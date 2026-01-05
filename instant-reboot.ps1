# Instant Reboot Script - Zero Delay, No Prompts
# PowerShell 5.x Compatible - Guaranteed Immediate Reboot
# WARNING: This will immediately reboot without saving anything!

# Suppress all errors to prevent any pauses
$ErrorActionPreference = 'SilentlyContinue'

# Check if running as Administrator - auto-elevate if not
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch as admin
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Method 1: WMI Win32Shutdown - Most reliable for PS5
try {
    $os = Get-WmiObject -Class Win32_OperatingSystem -EnableAllPrivileges
    $os.PSBase.Scope.Options.EnablePrivileges = $true
    # Reboot (2) + Force (4) = 6
    $os.Win32Shutdown(6) | Out-Null
} catch {}

# Method 2: Direct Windows API call - Fastest method
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class RebootAPI {
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

    public const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    public const uint TOKEN_QUERY = 0x0008;
    public const uint SE_PRIVILEGE_ENABLED = 0x00000002;
    public const string SE_SHUTDOWN_NAME = "SeShutdownPrivilege";

    public static bool EnableShutdownPrivilege() {
        try {
            IntPtr tokenHandle;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out tokenHandle))
                return false;

            TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
            tp.PrivilegeCount = 1;
            if (!LookupPrivilegeValue(null, SE_SHUTDOWN_NAME, out tp.Luid))
                return false;
            tp.Attributes = SE_PRIVILEGE_ENABLED;

            return AdjustTokenPrivileges(tokenHandle, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        } catch {
            return false;
        }
    }
}
"@ -ErrorAction SilentlyContinue

    # Enable shutdown privilege and reboot
    [RebootAPI]::EnableShutdownPrivilege() | Out-Null
    [RebootAPI]::NtShutdownSystem(1) | Out-Null
} catch {}

# Method 3: Restart-Computer cmdlet with force
try {
    Restart-Computer -Force -ErrorAction SilentlyContinue
} catch {}

# Method 4: shutdown.exe - Traditional fallback
shutdown /r /t 0 /f 2>$null

# Method 5: WMIC - Alternative fallback
wmic os where Primary=TRUE reboot 2>$null

# If all else fails, force critical process termination to trigger reboot
taskkill /F /IM winlogon.exe 2>$null
