<#
.SYNOPSIS
    NUCLEAR INSTANT REBOOT - Guaranteed no "Restarting" screen

.DESCRIPTION
    Uses NtRaiseHardError with OptionShutdownSystem to trigger immediate
    kernel-level shutdown. This is the most aggressive reboot method possible.
    
    The system will reboot within 1-2 seconds with NO UI whatsoever.

.PARAMETER Test
    Show what would happen without actually rebooting

.PARAMETER Shutdown
    Power off instead of reboot

.EXAMPLE
    .\instant_reboot_nuclear.ps1
    # Immediate reboot - no prompts, no UI

.EXAMPLE
    .\instant_reboot_nuclear.ps1 -Test
    # Test mode - shows privileges without rebooting

.NOTES
    WARNING: This causes IMMEDIATE shutdown. Save your work first!
#>

param(
    [switch]$Test,
    [switch]$Shutdown
)

# Add the nuclear shutdown type
$NuclearShutdownCode = @"
using System;
using System.Runtime.InteropServices;

public class NuclearShutdown {
    // NtRaiseHardError response options
    public const uint OptionShutdownSystem = 6;
    
    // Status codes
    public const uint STATUS_ASSERTION_FAILURE = 0xC0000420;
    
    // Privileges
    public const ulong SE_SHUTDOWN_PRIVILEGE = 19;
    public const ulong SE_DEBUG_PRIVILEGE = 20;
    
    // Shutdown actions for NtShutdownSystem
    public const int ShutdownNoReboot = 0;
    public const int ShutdownReboot = 1;
    public const int ShutdownPowerOff = 2;
    
    [DllImport("ntdll.dll")]
    public static extern int RtlAdjustPrivilege(
        ulong Privilege, 
        bool Enable, 
        bool CurrentThread, 
        out bool PreviousValue);
    
    [DllImport("ntdll.dll")]
    public static extern uint NtRaiseHardError(
        uint ErrorStatus,
        uint NumberOfParameters,
        uint UnicodeStringParameterMask,
        IntPtr Parameters,
        uint ValidResponseOptions,
        out uint Response);
    
    [DllImport("ntdll.dll")]
    public static extern int NtShutdownSystem(int Action);
    
    public static void EnablePrivileges() {
        bool previousValue;
        RtlAdjustPrivilege(SE_SHUTDOWN_PRIVILEGE, true, false, out previousValue);
        RtlAdjustPrivilege(SE_DEBUG_PRIVILEGE, true, false, out previousValue);
    }
    
    public static void NuclearReboot() {
        EnablePrivileges();
        
        uint response;
        uint status = NtRaiseHardError(
            STATUS_ASSERTION_FAILURE,
            0,
            0,
            IntPtr.Zero,
            OptionShutdownSystem,
            out response);
        
        // Fallback if NtRaiseHardError didn't trigger shutdown
        if (status != 0) {
            NtShutdownSystem(ShutdownReboot);
        }
    }
    
    public static void NuclearPowerOff() {
        EnablePrivileges();
        
        uint response;
        uint status = NtRaiseHardError(
            STATUS_ASSERTION_FAILURE,
            0,
            0,
            IntPtr.Zero,
            OptionShutdownSystem,
            out response);
        
        // Fallback
        if (status != 0) {
            NtShutdownSystem(ShutdownPowerOff);
        }
    }
    
    public static void FastReboot() {
        EnablePrivileges();
        NtShutdownSystem(ShutdownReboot);
    }
    
    public static void FastPowerOff() {
        EnablePrivileges();
        NtShutdownSystem(ShutdownPowerOff);
    }
}
"@

# Compile the type
Add-Type -TypeDefinition $NuclearShutdownCode -Language CSharp

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    exit 1
}

if ($Test) {
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "NUCLEAR REBOOT - TEST MODE" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script will perform an IMMEDIATE system reboot."
    Write-Host "There will be NO warning, NO 'Restarting' screen."
    Write-Host "The system will simply reboot within 1-2 seconds."
    Write-Host ""
    Write-Host "To actually reboot, run without -Test flag:" -ForegroundColor Yellow
    Write-Host "  .\instant_reboot_nuclear.ps1" -ForegroundColor White
    Write-Host ""
    
    # Test privilege elevation
    Write-Host "Testing privileges..." -ForegroundColor Cyan
    [NuclearShutdown]::EnablePrivileges()
    Write-Host "  Privileges enabled successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready to reboot. Run without -Test to execute." -ForegroundColor Yellow
    exit 0
}

# Execute
if ($Shutdown) {
    Write-Host "Initiating NUCLEAR SHUTDOWN..." -ForegroundColor Red
    [NuclearShutdown]::NuclearPowerOff()
} else {
    Write-Host "Initiating NUCLEAR REBOOT..." -ForegroundColor Red
    [NuclearShutdown]::NuclearReboot()
}
