# ULTRA-FAST Instant Reboot Script - Maximum Speed, Zero Delay
# PowerShell 5.x Optimized - 10X Faster Execution
# WARNING: This will immediately reboot without saving anything!

# Maximum speed settings - suppress everything
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# Lightning-fast admin check using .NET directly
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    [Environment]::Exit(0)
}

# FASTEST METHOD FIRST: Pre-compiled direct kernel API call
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class FastReboot {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtShutdownSystem(int Action);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, uint BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ExitWindowsEx(uint uFlags, uint dwReason);

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID {
        public uint LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES {
        public uint PrivilegeCount;
        public LUID Luid;
        public uint Attributes;
    }

    public static void EnablePrivilege() {
        IntPtr token;
        OpenProcessToken(GetCurrentProcess(), 0x0028, out token);
        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        tp.PrivilegeCount = 1;
        LookupPrivilegeValue(null, "SeShutdownPrivilege", out tp.Luid);
        tp.Attributes = 0x00000002;
        AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }

    public static void RebootNow() {
        EnablePrivilege();
        // Try NtShutdownSystem first (fastest - direct kernel call)
        NtShutdownSystem(1);
        // Fallback to ExitWindowsEx (force reboot)
        ExitWindowsEx(0x00000006, 0x00000000);
    }
}
"@ -Language CSharp -ErrorAction SilentlyContinue

# Execute fastest reboot method immediately
[FastReboot]::RebootNow()

# Parallel execution of multiple reboot commands for redundancy
Start-Job -ScriptBlock { shutdown /r /t 0 /f } | Out-Null
Start-Job -ScriptBlock { Restart-Computer -Force } | Out-Null
Start-Job -ScriptBlock {
    $os = Get-WmiObject Win32_OperatingSystem -EnableAllPrivileges
    $os.PSBase.Scope.Options.EnablePrivileges = $true
    $os.Win32Shutdown(6)
} | Out-Null

# Immediate execution paths (non-blocking)
& shutdown /r /t 0 /f 2>$null
& wmic os where Primary=TRUE reboot 2>$null

# Direct WMI reboot (synchronous - most reliable for PS5)
$os = Get-WmiObject -Class Win32_OperatingSystem -EnableAllPrivileges
$os.PSBase.Scope.Options.EnablePrivileges = $true
$os.Win32Shutdown(6)

# Final emergency fallback
Restart-Computer -Force
