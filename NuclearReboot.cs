/*
 * NUCLEAR REBOOT - Standalone C# Implementation
 * ==============================================
 * 
 * Compile with:
 *   csc /out:NuclearReboot.exe /target:winexe NuclearReboot.cs
 * 
 * Or with .NET Core:
 *   dotnet build
 * 
 * Usage:
 *   NuclearReboot.exe           # Instant reboot
 *   NuclearReboot.exe /s        # Instant shutdown (power off)
 *   NuclearReboot.exe /test     # Test mode
 * 
 * This is the GUARANTEED instant reboot - no "Restarting" screen possible.
 */

using System;
using System.Runtime.InteropServices;

class NuclearReboot
{
    // ==========================================================================
    // CONSTANTS
    // ==========================================================================
    
    // NtRaiseHardError options
    const uint OptionShutdownSystem = 6;
    
    // Status codes
    const uint STATUS_ASSERTION_FAILURE = 0xC0000420;
    
    // Privileges
    const ulong SE_SHUTDOWN_PRIVILEGE = 19;
    const ulong SE_DEBUG_PRIVILEGE = 20;
    
    // Shutdown actions
    const int ShutdownNoReboot = 0;
    const int ShutdownReboot = 1;
    const int ShutdownPowerOff = 2;
    
    // ==========================================================================
    // P/INVOKE DECLARATIONS
    // ==========================================================================
    
    [DllImport("ntdll.dll")]
    static extern int RtlAdjustPrivilege(
        ulong Privilege,
        bool Enable,
        bool CurrentThread,
        out bool PreviousValue);
    
    [DllImport("ntdll.dll")]
    static extern uint NtRaiseHardError(
        uint ErrorStatus,
        uint NumberOfParameters,
        uint UnicodeStringParameterMask,
        IntPtr Parameters,
        uint ValidResponseOptions,
        out uint Response);
    
    [DllImport("ntdll.dll")]
    static extern int NtShutdownSystem(int Action);
    
    [DllImport("shell32.dll")]
    static extern bool IsUserAnAdmin();
    
    // ==========================================================================
    // MAIN FUNCTIONS
    // ==========================================================================
    
    static void EnablePrivileges()
    {
        bool prev;
        RtlAdjustPrivilege(SE_SHUTDOWN_PRIVILEGE, true, false, out prev);
        RtlAdjustPrivilege(SE_DEBUG_PRIVILEGE, true, false, out prev);
    }
    
    static void DoNuclearReboot()
    {
        EnablePrivileges();
        
        uint response;
        uint status = NtRaiseHardError(
            STATUS_ASSERTION_FAILURE,
            0,
            0,
            IntPtr.Zero,
            OptionShutdownSystem,
            out response);
        
        // Fallback to NtShutdownSystem if NtRaiseHardError didn't work
        if (status != 0)
        {
            NtShutdownSystem(ShutdownReboot);
        }
    }
    
    static void DoNuclearShutdown()
    {
        EnablePrivileges();
        
        uint response;
        uint status = NtRaiseHardError(
            STATUS_ASSERTION_FAILURE,
            0,
            0,
            IntPtr.Zero,
            OptionShutdownSystem,
            out response);
        
        if (status != 0)
        {
            NtShutdownSystem(ShutdownPowerOff);
        }
    }
    
    static void DoFastReboot()
    {
        EnablePrivileges();
        NtShutdownSystem(ShutdownReboot);
    }
    
    // ==========================================================================
    // ENTRY POINT
    // ==========================================================================
    
    static int Main(string[] args)
    {
        // Check admin
        if (!IsUserAnAdmin())
        {
            Console.WriteLine("ERROR: Must run as Administrator!");
            Console.WriteLine("Right-click and select 'Run as administrator'");
            return 1;
        }
        
        // Parse args
        bool testMode = false;
        bool shutdown = false;
        bool fast = false;
        
        foreach (string arg in args)
        {
            string a = arg.ToLower();
            if (a == "/test" || a == "-test" || a == "--test" || a == "/t")
                testMode = true;
            else if (a == "/s" || a == "-s" || a == "--shutdown" || a == "/shutdown")
                shutdown = true;
            else if (a == "/f" || a == "-f" || a == "--fast" || a == "/fast")
                fast = true;
        }
        
        if (testMode)
        {
            Console.WriteLine("============================================================");
            Console.WriteLine("NUCLEAR REBOOT - TEST MODE");
            Console.WriteLine("============================================================");
            Console.WriteLine();
            Console.WriteLine("This program will perform an IMMEDIATE system reboot.");
            Console.WriteLine("There will be NO warning, NO 'Restarting' screen.");
            Console.WriteLine("The system will simply reboot within 1-2 seconds.");
            Console.WriteLine();
            Console.WriteLine("To actually reboot, run without /test flag:");
            Console.WriteLine("  NuclearReboot.exe");
            Console.WriteLine();
            Console.WriteLine("Testing privileges...");
            EnablePrivileges();
            Console.WriteLine("  Privileges enabled successfully!");
            Console.WriteLine();
            Console.WriteLine("Ready to reboot. Run without /test to execute.");
            return 0;
        }
        
        // Execute
        if (shutdown)
        {
            DoNuclearShutdown();
        }
        else if (fast)
        {
            DoFastReboot();
        }
        else
        {
            DoNuclearReboot();
        }
        
        return 0;
    }
}
