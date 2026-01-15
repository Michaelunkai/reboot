<#
.SYNOPSIS
    Shutdown Hook - Intercepts shutdown.exe calls and performs instant reboot/shutdown.

.DESCRIPTION
    This script is designed to be used with Image File Execution Options (IFEO)
    to intercept shutdown.exe calls and perform instant NtShutdownSystem operations.
    
    When shutdown.exe is called (by Start menu, Ctrl+Alt+Del, etc.), this script
    intercepts the call and performs an immediate shutdown without delays.

.PARAMETER Arguments
    The original arguments passed to shutdown.exe
    
.EXAMPLE
    Triggered automatically when shutdown.exe is invoked via IFEO
    
.NOTES
    Setup IFEO with:
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\shutdown.exe" /v Debugger /t REG_SZ /d "powershell.exe -ExecutionPolicy Bypass -File C:\Program Files\InstantReboot\shutdown_hook.ps1" /f
#>

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

# Parse the command line - first arg is the original executable path
$originalExe = $RemainingArgs[0]
$args = if ($RemainingArgs.Count -gt 1) { $RemainingArgs[1..($RemainingArgs.Count-1)] } else { @() }

# Log file for debugging
$logFile = "$env:ProgramData\InstantReboot\shutdown_hook.log"
$logDir = Split-Path $logFile -Parent
if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

Write-Log "Shutdown hook triggered. Original exe: $originalExe, Args: $($args -join ' ')"

# Add the NtShutdown type
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class NtShutdown {
    [DllImport("ntdll.dll")]
    public static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, out bool OldValue);
    
    [DllImport("ntdll.dll")]
    public static extern int NtShutdownSystem(int Action);
    
    public const int ShutdownNoReboot = 0;
    public const int ShutdownReboot = 1;
    public const int ShutdownPowerOff = 2;
    public const ulong SeShutdownPrivilege = 19;
    
    public static void InstantReboot() {
        bool oldValue;
        RtlAdjustPrivilege(SeShutdownPrivilege, true, false, out oldValue);
        NtShutdownSystem(ShutdownReboot);
    }
    
    public static void InstantShutdown() {
        bool oldValue;
        RtlAdjustPrivilege(SeShutdownPrivilege, true, false, out oldValue);
        NtShutdownSystem(ShutdownPowerOff);
    }
}
"@

# Parse arguments to determine action
$argString = $args -join ' '
$isReboot = $argString -match '/r|/g|-r|-g'
$isShutdown = $argString -match '/s|-s'
$isPowerOff = $argString -match '/p|-p'
$isAbort = $argString -match '/a|-a'
$isHibernate = $argString -match '/h|-h'
$isLogoff = $argString -match '/l|-l'
$isHelp = $argString -match '/\?|-\?|--help'

Write-Log "Parsed: Reboot=$isReboot, Shutdown=$isShutdown, PowerOff=$isPowerOff, Abort=$isAbort"

# Handle special cases that should pass through
if ($isAbort -or $isHelp -or $isLogoff -or $isHibernate) {
    Write-Log "Passing through to original shutdown.exe"
    # Call the real shutdown.exe (it's been renamed or we use the system32 copy)
    $realShutdown = "$env:SystemRoot\System32\shutdown_original.exe"
    if (!(Test-Path $realShutdown)) {
        $realShutdown = "$env:SystemRoot\System32\shutdown.exe"
    }
    Start-Process -FilePath $realShutdown -ArgumentList $args -NoNewWindow -Wait
    exit
}

# Perform instant operation
try {
    if ($isReboot) {
        Write-Log "Performing instant REBOOT"
        [NtShutdown]::InstantReboot()
    } else {
        # Default to shutdown/poweroff
        Write-Log "Performing instant SHUTDOWN"
        [NtShutdown]::InstantShutdown()
    }
} catch {
    Write-Log "ERROR: $_"
    # Fallback to original shutdown
    Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList "/r /f /t 0" -NoNewWindow
}
