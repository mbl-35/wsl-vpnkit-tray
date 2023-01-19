# Toggle following two lines
Set-StrictMode -Version Latest
# Set-StrictMode -Off


# Add assemblies for WPF
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')    | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework')   | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')          | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null

$Version="1.0.1"
$WslDistributionName = "wsl-vpnkit"

# ----------------------------------------------------
# Part - Build icons
# ----------------------------------------------------

function Convert-Base64ToIcon([String] $Base64Icon)
{
    # $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    # $bitmap.BeginInit()
    # $bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Base64Icon)
    # $bitmap.EndInit()
    # $bitmap.Freeze()
    # $image = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($bitmap.StreamSource)
    # return [System.Drawing.Icon]::FromHandle($image.GetHicon())
    $iconBytes = [Convert]::FromBase64String($Base64Icon)
    $stream    = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
    $image     = [System.Drawing.Bitmap]::new($stream)
    return [System.Drawing.Icon]::FromHandle($image.GetHIcon())
}



if ($null -ne $args[0] -AND $args[0].Trim() -eq "--version") {
    Write-Host "$Version"
    exit 1

}


# Choose an icons to display status in the systray
# Images from : https://iconarchive.com/show/oxygen-icons-by-oxygen-icons.org/Status-user-offline-icon.html
$undetectedIcon = Convert-Base64ToIcon "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"
$onlineIcon = Convert-Base64ToIcon "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"
$offlineIcon = Convert-Base64ToIcon "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"

# Visible Tray Icon
$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "Wsl-Vpnkit"
$Main_Tool_Icon.Icon = $undetectedIcon
$Main_Tool_Icon.Visible = $true



# ----------------------------------------------------
# Part - Add the systray menu
# ----------------------------------------------------

# Create menu items
$Menu_Label = New-Object System.Windows.Forms.MenuItem
$Menu_Label.Text = "WSL VpnKit - v$Version"
$Menu_Label.Enabled = $false

$Menu_Start = New-Object System.Windows.Forms.MenuItem
$Menu_Start.Text = "    Start"

$Menu_Stop = New-Object System.Windows.Forms.MenuItem
$Menu_Stop.Text = "    Stop"

$Menu_Exit = New-Object System.Windows.Forms.MenuItem
$Menu_Exit.Text = "Exit"


# Add menu items to context menu
$contextmenu = New-Object System.Windows.Forms.ContextMenu
$Main_Tool_Icon.ContextMenu = $contextmenu
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Label)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Start)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Stop)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange("-")
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)



# ---------------------------------------------------------------------
# Action when after a click on the systray icon
# ---------------------------------------------------------------------
$Main_Tool_Icon.Add_Click({
        If ($_.Button -eq [Windows.Forms.MouseButtons]::Left)
        {
            $Main_Tool_Icon.GetType().GetMethod("ShowContextMenu", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic).Invoke($Main_Tool_Icon, $null)
        }
    })


# When Start is clicked, start stayawake job and get its pid
$Menu_Start.add_Click({
        $Menu_Stop.Enabled = $true
        $Menu_Start.Enabled = $false
        wsl --distribution "$WslDistributionName" service wsl-vpnkit start
        #Stop-Job -Name "keepAwake"
        #Start-Job -ScriptBlock $keepAwakeScript -Name "keepAwake"
    })

# When Stop is clicked, kill stay awake job
$Menu_Stop.add_Click({
        $Menu_Stop.Enabled = $false
        $Menu_Start.Enabled = $true
        wsl --distribution "$WslDistributionName" service wsl-vpnkit stop
        wsl --distribution "$WslDistributionName" --terminate
        Stop-Process -Name wsl-vpnkit -Force -ErrorAction SilentlyContinue
        #Stop-Job -Name "keepAwake"
    })

# When Exit is clicked, close everything and kill the PowerShell process
$Menu_Exit.add_Click({
        $Main_Tool_Icon.Visible = $false
        [System.Windows.Forms.Application]::Exit()
        Stop-Process -Id $PID
    })



# ---------------------------------------------------------------------
# Action to keep system status
# ---------------------------------------------------------------------

function Get-Status([string] $name)
{
     # Inexplicably, wsl --list --running produces UTF-16LE-encoded
    # ("Unicode"-encoded) output rather than respecting the
    # console's (OEM) code page.
    $prev = [Console]::OutputEncoding;
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $result = (wsl --list --verbose | Select-Object -Skip 1) | Where-Object { $_ -ne "" }
    [Console]::OutputEncoding = $prev

    return ( ($result | Select-String -Pattern " +$name +" | Out-String).Trim() -Split '[\*\s]+' | Where-Object { $_ } )
}


# Initialize the timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.Add_Tick({
        $status = get-Status $WslDistributionName

        $Menu_Start.Enabled, $Menu_Stop.Enabled, $Main_Tool_Icon.Icon = if (-Not $status)
        {
            # Command not detected
            $false, $false, $undetectedIcon
        }
        elseif ("$status" -Match "\w Running \d")
        {
            # Command is running
            $false, $true, $onlineIcon
        }
        else
        {
            # Command is not running
            $true, $false, $offlineIcon
        }
    })
$timer.Start()



# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)



# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()



# Create an application context for it to all run within.
# This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)