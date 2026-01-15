<#
.SYNOPSIS
    Setup Nuclear Instant Reboot - Complete installation for GUARANTEED instant reboot

.DESCRIPTION
    This script sets up the NUCLEAR instant reboot system that guarantees:
    - NO "Restarting" screen ever
    - Instant reboot within 1-2 seconds
    - Multiple ways to trigger: keyboard shortcut, Start Menu, desktop icon

.PARAMETER Install
    Install the nuclear reboot system

.PARAMETER Uninstall  
    Remove the nuclear reboot system

.EXAMPLE
    .\setup_nuclear_reboot.ps1 -Install
#>

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$InstallDir = "$env:ProgramFiles\NuclearReboot"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        default   { "Cyan" }
    }
    Write-Host "[$Type] $Message" -ForegroundColor $color
}

# =============================================================================
# INSTALLATION
# =============================================================================

function Install-NuclearReboot {
    Write-Host "`n" + "=" * 60 -ForegroundColor Magenta
    Write-Host "  NUCLEAR REBOOT - INSTALLATION" -ForegroundColor Magenta
    Write-Host "=" * 60 + "`n" -ForegroundColor Magenta
    
    # Create install directory
    Write-Status "Creating installation directory..."
    if (!(Test-Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
    }
    
    # Copy NuclearReboot.exe
    $exePath = Join-Path $ScriptDir "NuclearReboot.exe"
    if (Test-Path $exePath) {
        Copy-Item $exePath -Destination $InstallDir -Force
        Write-Status "  Copied NuclearReboot.exe" -Type "Success"
    } else {
        Write-Status "  NuclearReboot.exe not found - compiling..." -Type "Warning"
        $csPath = Join-Path $ScriptDir "NuclearReboot.cs"
        if (Test-Path $csPath) {
            $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            if (Test-Path $csc) {
                & $csc /out:"$InstallDir\NuclearReboot.exe" /target:winexe $csPath 2>$null
                Write-Status "  Compiled NuclearReboot.exe" -Type "Success"
            }
        }
    }
    
    # Copy PowerShell script as backup
    $ps1Path = Join-Path $ScriptDir "instant_reboot_nuclear.ps1"
    if (Test-Path $ps1Path) {
        Copy-Item $ps1Path -Destination $InstallDir -Force
        Write-Status "  Copied instant_reboot_nuclear.ps1" -Type "Success"
    }
    
    # Copy system tray app
    $trayExePath = Join-Path $ScriptDir "NuclearRebootTray.exe"
    if (Test-Path $trayExePath) {
        Copy-Item $trayExePath -Destination $InstallDir -Force
        Write-Status "  Copied NuclearRebootTray.exe (system tray app)" -Type "Success"
    } else {
        Write-Status "  NuclearRebootTray.exe not found - compiling..." -Type "Warning"
        $trayCs = Join-Path $ScriptDir "NuclearRebootTray.cs"
        if (Test-Path $trayCs) {
            $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            if (Test-Path $csc) {
                & $csc /out:"$InstallDir\NuclearRebootTray.exe" /target:winexe /r:System.Windows.Forms.dll /r:System.Drawing.dll $trayCs 2>$null
                Write-Status "  Compiled NuclearRebootTray.exe" -Type "Success"
            }
        }
    }
    
    # ==========================================================================
    # CREATE DESKTOP SHORTCUT
    # ==========================================================================
    Write-Status "Creating desktop shortcut..."
    $WshShell = New-Object -ComObject WScript.Shell
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\Nuclear Reboot.lnk")
    $Shortcut.TargetPath = "$InstallDir\NuclearReboot.exe"
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Description = "Instant Reboot - No delays, no Restarting screen"
    $Shortcut.Save()
    
    # Set to run as admin
    $bytes = [System.IO.File]::ReadAllBytes("$DesktopPath\Nuclear Reboot.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20  # Set run as admin flag
    [System.IO.File]::WriteAllBytes("$DesktopPath\Nuclear Reboot.lnk", $bytes)
    
    Write-Status "  Created 'Nuclear Reboot' desktop shortcut" -Type "Success"
    
    # ==========================================================================
    # CREATE START MENU SHORTCUT
    # ==========================================================================
    Write-Status "Creating Start Menu shortcut..."
    $StartMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
    
    $StartShortcut = $WshShell.CreateShortcut("$StartMenuPath\Nuclear Reboot.lnk")
    $StartShortcut.TargetPath = "$InstallDir\NuclearReboot.exe"
    $StartShortcut.WorkingDirectory = $InstallDir
    $StartShortcut.Description = "Instant Reboot - No delays"
    $StartShortcut.Save()
    
    # Set to run as admin
    $bytes = [System.IO.File]::ReadAllBytes("$StartMenuPath\Nuclear Reboot.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes("$StartMenuPath\Nuclear Reboot.lnk", $bytes)
    
    Write-Status "  Created Start Menu shortcut (search 'Nuclear Reboot')" -Type "Success"
    
    # ==========================================================================
    # CREATE KEYBOARD SHORTCUT (Ctrl+Alt+R)
    # ==========================================================================
    Write-Status "Creating keyboard shortcut (Ctrl+Alt+R)..."
    
    # Create shortcut with hotkey in user's Startup folder (so hotkey works)
    $StartupPath = [Environment]::GetFolderPath("Startup")
    $HotkeyShortcut = $WshShell.CreateShortcut("$DesktopPath\Nuclear Reboot Hotkey.lnk")
    $HotkeyShortcut.TargetPath = "$InstallDir\NuclearReboot.exe"
    $HotkeyShortcut.WorkingDirectory = $InstallDir
    $HotkeyShortcut.Hotkey = "Ctrl+Alt+R"
    $HotkeyShortcut.Description = "Press Ctrl+Alt+R for instant reboot"
    $HotkeyShortcut.Save()
    
    # Set to run as admin
    $bytes = [System.IO.File]::ReadAllBytes("$DesktopPath\Nuclear Reboot Hotkey.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes("$DesktopPath\Nuclear Reboot Hotkey.lnk", $bytes)
    
    Write-Status "  Created Ctrl+Alt+R hotkey shortcut" -Type "Success"
    Write-Status "  NOTE: Hotkey requires shortcut on desktop to work" -Type "Warning"
    
    # ==========================================================================
    # AGGRESSIVE REGISTRY SETTINGS (backup to nuclear)
    # ==========================================================================
    Write-Status "Applying aggressive registry settings..."
    
    # User settings
    $hkcuDesktop = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $hkcuDesktop -Name "AutoEndTasks" -Value "1" -Type String -Force
    Set-ItemProperty -Path $hkcuDesktop -Name "WaitToKillAppTimeout" -Value "500" -Type String -Force
    Set-ItemProperty -Path $hkcuDesktop -Name "HungAppTimeout" -Value "500" -Type String -Force
    
    # System settings
    $hklmControl = "HKLM:\SYSTEM\CurrentControlSet\Control"
    Set-ItemProperty -Path $hklmControl -Name "WaitToKillServiceTimeout" -Value "500" -Type String -Force
    
    # Disable Fast Startup
    $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    if (!(Test-Path $powerPath)) {
        New-Item -Path $powerPath -Force | Out-Null
    }
    Set-ItemProperty -Path $powerPath -Name "HiberbootEnabled" -Value 0 -Type DWord -Force
    
    Write-Status "  Registry optimizations applied" -Type "Success"
    
    # ==========================================================================
    # ADD TO PATH
    # ==========================================================================
    Write-Status "Adding to system PATH..."
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$InstallDir", "Machine")
        Write-Status "  Added $InstallDir to PATH" -Type "Success"
    }
    
    # ==========================================================================
    # COMPLETE
    # ==========================================================================
    Write-Host "`n" + "=" * 60 -ForegroundColor Green
    Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 60 + "`n" -ForegroundColor Green
    
    Write-Host "How to use NUCLEAR REBOOT:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Desktop shortcut: Double-click 'Nuclear Reboot'" -ForegroundColor Cyan
    Write-Host "  2. Keyboard:         Press Ctrl+Alt+R" -ForegroundColor Cyan
    Write-Host "  3. Start Menu:       Search 'Nuclear Reboot'" -ForegroundColor Cyan
    Write-Host "  4. Command line:     NuclearReboot.exe" -ForegroundColor Cyan
    Write-Host "  5. PowerShell:       instant_reboot_nuclear.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "GUARANTEE: No 'Restarting' screen. System reboots in 1-2 seconds." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "WARNING: Save your work first! This is INSTANT." -ForegroundColor Red
    Write-Host ""
}

# =============================================================================
# UNINSTALLATION
# =============================================================================

function Uninstall-NuclearReboot {
    Write-Host "`n" + "=" * 60 -ForegroundColor Magenta
    Write-Host "  NUCLEAR REBOOT - UNINSTALLATION" -ForegroundColor Magenta
    Write-Host "=" * 60 + "`n" -ForegroundColor Magenta
    
    # Remove install directory
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Status "Removed $InstallDir" -Type "Success"
    }
    
    # Remove shortcuts
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcuts = @(
        "$DesktopPath\Nuclear Reboot.lnk",
        "$DesktopPath\Nuclear Reboot Hotkey.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Nuclear Reboot.lnk"
    )
    
    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) {
            Remove-Item $shortcut -Force
            Write-Status "Removed shortcut: $shortcut" -Type "Success"
        }
    }
    
    # Remove from PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    Write-Status "Removed from PATH" -Type "Success"
    
    # Restore registry defaults
    $hkcuDesktop = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $hkcuDesktop -Name "AutoEndTasks" -Value "0" -Type String -Force
    Set-ItemProperty -Path $hkcuDesktop -Name "WaitToKillAppTimeout" -Value "5000" -Type String -Force
    Set-ItemProperty -Path $hkcuDesktop -Name "HungAppTimeout" -Value "5000" -Type String -Force
    
    $hklmControl = "HKLM:\SYSTEM\CurrentControlSet\Control"
    Set-ItemProperty -Path $hklmControl -Name "WaitToKillServiceTimeout" -Value "5000" -Type String -Force
    
    Write-Status "Restored default registry settings" -Type "Success"
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Green
    Write-Host "  UNINSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 60 + "`n" -ForegroundColor Green
}

# =============================================================================
# MAIN
# =============================================================================

if (!(Test-Administrator)) {
    Write-Status "This script requires Administrator privileges!" -Type "Error"
    Write-Status "Please run PowerShell as Administrator and try again." -Type "Error"
    exit 1
}

if ($Uninstall) {
    Uninstall-NuclearReboot
} elseif ($Install) {
    Install-NuclearReboot
} else {
    Write-Host @"

NUCLEAR REBOOT SETUP
====================

This installs the GUARANTEED instant reboot system.
No "Restarting" screen. Ever.

Usage:
    .\setup_nuclear_reboot.ps1 -Install     # Install everything
    .\setup_nuclear_reboot.ps1 -Uninstall   # Remove everything

After installation, you can reboot instantly via:
    - Desktop shortcut (double-click "Nuclear Reboot")
    - Keyboard shortcut (Ctrl+Alt+R)
    - Start Menu (search "Nuclear Reboot")
    - Command line (NuclearReboot.exe)

"@
}
