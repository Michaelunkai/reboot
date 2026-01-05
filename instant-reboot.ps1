# Instant Reboot Script - Zero Delay, No Prompts
# WARNING: This will immediately reboot without saving anything!

# Method 1: Direct Windows API call - fastest method
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NativeMethods {
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

    public static void EnableShutdownPrivilege() {
        IntPtr tokenHandle;
        OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out tokenHandle);

        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        tp.PrivilegeCount = 1;
        LookupPrivilegeValue(null, SE_SHUTDOWN_NAME, out tp.Luid);
        tp.Attributes = SE_PRIVILEGE_ENABLED;

        AdjustTokenPrivileges(tokenHandle, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }
}
"@

# Enable shutdown privilege
[NativeMethods]::EnableShutdownPrivilege()

# NtShutdownSystem Actions: 0=Shutdown, 1=Reboot, 2=PowerOff
# This bypasses all shutdown dialogs and timers
[NativeMethods]::NtShutdownSystem(1)

# Fallback if NtShutdownSystem doesn't work
shutdown /r /t 0 /f
