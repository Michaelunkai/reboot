# Instant Reboot Script - Clean and Safe
# PowerShell 5.x Compatible - Immediate Reboot, No Explorer Issues
# WARNING: This will immediately reboot without saving anything!

# Suppress errors and output for speed
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Check admin privileges and elevate if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Use the most reliable method: shutdown.exe with force and zero timeout
# /r = reboot, /t 0 = zero seconds timeout, /f = force close applications
shutdown /r /t 0 /f
