# Requires -Modules 'InvokeBuild'

param (
    [ValidateSet("Release", "Test","all")]$Configuration = "Test",
    [Parameter(Mandatory = $false)][Switch]$ciMode = $false
)


$Settings = @{

    AppName = "wsl-vpnkit-tray"
    BuildOutput = "$PSScriptRoot\build"
    DistFolder = "$PSScriptRoot\build\dist"
    TestDependency = @('Pester','PsScriptAnalyzer','InvokeBuild')
    BuildDependency = @('InvokeBuild')
    SourceFolder = "$PSScriptRoot\src"

    UnitTestParams = @{
        Script = '.\tests\unit'
        OutputFormat = 'NUnitXml'
        OutputFile = "$PSScriptRoot\build\UnitTestsResult.xml"
        PassThru = $True
    }

    IntegrationTestParams = @{
        Script = '.\tests\integration'
        OutputFile = "$PSScriptRoot\build\IntegrationTestsResult.xml"
        PassThru = $True
    }

    AnalyzeParams = @{
        Path = '.\src'
        Severity = @('ParseError', 'Error','Warning', 'Information')
        Recurse = $True
        ExcludeRule = @('PSAvoidUsingWriteHost')
    }
}

if ($ciMode) { $Settings.AnalyzeParams.Severity = @('ParseError', 'Error') }

Set-BuildHeader {
    Param($Path)
    Write-Build Cyan "Task $Path"
    "`n" + ('-' * 79) + "`n" + "`t`t`t $($Task.Name.ToUpper()) `n" + ('-' * 79) + "`n"
}

task Clean {
    if (Test-Path -Path $Settings.BuildOutput) {
        "Removing existing files and folders in $($Settings.BuildOutput)\"
        Get-ChildItem $Settings.BuildOutput | Remove-Item -Force -Recurse
    }
    else {
        "$($Settings.BuildOutput) is not present, nothing to clean up."
        $Null = New-Item -ItemType Directory -Path $Settings.BuildOutput
    }
}

task Install_Dependencies {
    switch ($Configuration) {
        Tests { $Dependencies = $Settings.TestDependency }
        Release { $Dependencies = $Settings.BuildDependency }
        all { $Dependencies = ($Settings.TestDependency + $Settings.BuildDependency) | Select-Object -Unique }
    }
    Foreach ( $Depend in $Dependencies ) {
        "Installing test dependency : $Depend"
        if ( $Depend -eq 'Selenium.WebDriver' ) {
            Install-Package $Depend -Source nuget.org -Force
        }
        else {
            if (-not(Get-Module -Name  $Depend -ListAvailable)) {
                Install-Module $Depend -Scope CurrentUser -Force -SkipPublisherCheck
            }
            Import-Module $Depend -Force
        }
    }
}

task Unit_Tests {
    $UnitTestSettings = $Settings.UnitTestParams
    if (-Not(Test-Path $UnitTestSettings.Script -PathType Container)) {
        Write-Warning "No unit tests defined - skip"
        $Script:UnitTestsResult = @{ FailedCount = 0}
    }
    else { $Script:UnitTestsResult = Invoke-Pester @UnitTestSettings}
}

task Fail_If_Failed_Unit_Test {
    $FailureMessage = '{0} Unit test(s) failed. Aborting build' -f $UnitTestsResult.FailedCount
    assert ($UnitTestsResult.FailedCount -eq 0) $FailureMessage
}


task Integration_Tests {
    $IntegrationTestSettings = $Settings.IntegrationTestParams
    if (-Not(Test-Path $IntegrationTestSettings.Script -PathType Container)) {
        Write-Warning "No integration tests defined - skip"
        $Script:IntegrationTestsResult = @{ FailedCount = 0}
    }
    else { $Script:IntegrationTestsResult = Invoke-Pester @IntegrationTestSettings }
}

task Fail_If_Failed_Integration_Test {
    $FailureMessage = '{0} Integration test(s) failed. Aborting build' -f $IntegrationTestsResult.FailedCount
    assert ($IntegrationTestsResult.FailedCount -eq 0) $FailureMessage
}


task Test Unit_Tests,
    Fail_If_Failed_Unit_Test,
    Integration_Tests,
    Fail_If_Failed_Integration_Test -if({ @("Test", "all") -contains $Configuration})


task Analyze_Code {
    $AnalyzeSettings = $Settings.AnalyzeParams
    Invoke-ScriptAnalyzer @AnalyzeSettings -Outvariable AnalyzeFindings | Out-Null
    $Script:AnalyzeFindings = $AnalyzeFindings
    if ( $AnalyzeFindings ) {
        $FindingsString = $AnalyzeFindings | Out-String
        Write-Warning $FindingsString
    }
}

task Fail_If_Analyze_Findings {
    $FailureMessage = 'PSScriptAnalyzer found {0} issues. Aborting build' -f $AnalyzeFindings.Count
    assert ( -not($AnalyzeFindings) ) $FailureMessage
}

task Analyze Analyze_Code,
    Fail_If_Analyze_Findings -if({ @("Test", "all") -contains $Configuration})



task Build_Initialize {
    if (Test-Path -Path $Settings.DistFolder) {
        "Removing existing files and folders in $($Settings.DistFolder)\"
        Get-ChildItem $Settings.DistFolder | Remove-Item -Force -Recurse
    }
    Write-Output "Extract $AppName App version"
    $AppName = $Settings.AppName
    $Version = (cmd /c powershell "$($Settings.SourceFolder)\$AppName.ps1" --version)

    $Settings.AppVersion = $Version
    $Settings.BuildParams = @{}
    @('win32','win64') | ForEach-Object -Process {
        $ArchiveFile = "$($Settings.DistFolder)\$AppName-v$Version-$_.zip"
        $Settings.BuildParams.Add($_, @{
            SourceFiles = $Settings.SourceFolder
            Version = $Version
            ArchiveFile = $ArchiveFile
        })
    }
    New-Item -Path "$($Settings.DistFolder)" -ItemType Directory -ErrorAction Stop | Out-Null
}

task Build_Archive_x32 {
    $BuildParams = $Settings.BuildParams.win32
    Write-Output "Compress Release File $($BuildParams.ArchiveFile)"
    Get-ChildItem -Path $BuildParams.SourceFiles -Exclude *.json |
        Compress-Archive -DestinationPath $BuildParams.ArchiveFile -Update
    $FailureMessage = 'Archive has compress issue(s). Aborting build'
    assert ( Test-Path $BuildParams.ArchiveFile ) $FailureMessage
}

task Build_Archive_x64 {
    $BuildParams = $Settings.BuildParams.win64
    Write-Output "Compress Release File $($BuildParams.ArchiveFile)"
    Get-ChildItem -Path $BuildParams.SourceFiles -Exclude *.json |
        Compress-Archive -DestinationPath $BuildParams.ArchiveFile -Update

    $FailureMessage = 'Archive has compress issue(s). Aborting build'
    assert ( Test-Path $BuildParams.ArchiveFile ) $FailureMessage
}


task Build Build_Initialize,
    Build_Archive_x32,
    Build_Archive_x64 -if({ @("Release", "all") -contains $Configuration})


task . Clean,
    Install_Dependencies,
    Test,
    Analyze,
    Build