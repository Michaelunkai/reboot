"""
INSTANT REBOOT - NUCLEAR OPTION (NtRaiseHardError)
===================================================
This is the GUARANTEED instant reboot that Windows CANNOT intercept.

Uses NtRaiseHardError with OptionShutdownSystem to trigger an immediate
kernel-level shutdown. This is the same mechanism Windows uses for
critical system errors - there is NO "Restarting" screen possible.

WARNING: This is extremely aggressive:
- NO chance to save data
- NO prompts of any kind
- System reboots IMMEDIATELY (within 1-2 seconds max)
- Similar to pulling the power cord, but cleaner

Usage:
    python instant_reboot_nuclear.py           # Instant reboot
    python instant_reboot_nuclear.py --test    # Test mode (shows what would happen)

Run as Administrator.
"""

import ctypes
import sys
from ctypes import wintypes, POINTER, byref, c_ulong, c_void_p

# =============================================================================
# CONSTANTS
# =============================================================================

# NtRaiseHardError response options
OptionAbortRetryIgnore = 0
OptionOk = 1
OptionOkCancel = 2
OptionRetryCancel = 3
OptionYesNo = 4
OptionYesNoCancel = 5
OptionShutdownSystem = 6  # This is what we want - immediate shutdown

# NT Status codes
STATUS_SUCCESS = 0
STATUS_ASSERTION_FAILURE = 0xC0000420  # We use this to trigger the hard error

# Privileges
SE_SHUTDOWN_PRIVILEGE = 19
SE_DEBUG_PRIVILEGE = 20

# =============================================================================
# DLL HANDLES
# =============================================================================

ntdll = ctypes.windll.ntdll
kernel32 = ctypes.windll.kernel32

# =============================================================================
# FUNCTION PROTOTYPES
# =============================================================================

# RtlAdjustPrivilege - Enable privileges
ntdll.RtlAdjustPrivilege.restype = wintypes.LONG
ntdll.RtlAdjustPrivilege.argtypes = [
    wintypes.ULONG,  # Privilege
    wintypes.BOOLEAN,  # Enable
    wintypes.BOOLEAN,  # CurrentThread
    POINTER(wintypes.BOOLEAN),  # PreviousValue
]

# NtRaiseHardError - Trigger system hard error (BSOD-level)
ntdll.NtRaiseHardError.restype = wintypes.LONG
ntdll.NtRaiseHardError.argtypes = [
    wintypes.LONG,  # ErrorStatus
    wintypes.ULONG,  # NumberOfParameters
    wintypes.ULONG,  # UnicodeStringParameterMask
    c_void_p,  # Parameters
    wintypes.ULONG,  # ValidResponseOptions
    POINTER(wintypes.ULONG),  # Response
]

# NtShutdownSystem - Backup method
ntdll.NtShutdownSystem.restype = wintypes.LONG
ntdll.NtShutdownSystem.argtypes = [wintypes.ULONG]

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================


def enable_privilege(privilege_id):
    """Enable a system privilege"""
    previous = wintypes.BOOLEAN()
    status = ntdll.RtlAdjustPrivilege(privilege_id, True, False, byref(previous))
    return status == 0


def is_admin():
    """Check if running as administrator"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


# =============================================================================
# NUCLEAR REBOOT FUNCTIONS
# =============================================================================


def nuclear_reboot():
    """
    Perform IMMEDIATE system reboot using NtRaiseHardError.

    This triggers a kernel-level hard error with OptionShutdownSystem,
    which causes Windows to immediately shut down and reboot.

    There is NO UI, NO delay, NO "Restarting" screen.
    The system simply reboots within 1-2 seconds.
    """
    # Enable required privileges
    enable_privilege(SE_SHUTDOWN_PRIVILEGE)
    enable_privilege(SE_DEBUG_PRIVILEGE)

    # Response variable
    response = wintypes.ULONG()

    # Trigger hard error with shutdown option
    # STATUS_ASSERTION_FAILURE with OptionShutdownSystem = immediate reboot
    status = ntdll.NtRaiseHardError(
        STATUS_ASSERTION_FAILURE,  # Error status (any critical error works)
        0,  # No parameters
        0,  # No unicode strings
        None,  # No parameter array
        OptionShutdownSystem,  # CRITICAL: This triggers immediate shutdown
        byref(response),
    )

    # If NtRaiseHardError didn't work, fall back to NtShutdownSystem
    if status != STATUS_SUCCESS:
        ntdll.NtShutdownSystem(1)  # 1 = Reboot


def nuclear_shutdown():
    """
    Perform IMMEDIATE system shutdown (power off) using NtRaiseHardError.
    """
    enable_privilege(SE_SHUTDOWN_PRIVILEGE)
    enable_privilege(SE_DEBUG_PRIVILEGE)

    response = wintypes.ULONG()

    # For shutdown, we use NtShutdownSystem with PowerOff after raising error
    status = ntdll.NtRaiseHardError(
        STATUS_ASSERTION_FAILURE, 0, 0, None, OptionShutdownSystem, byref(response)
    )

    if status != STATUS_SUCCESS:
        ntdll.NtShutdownSystem(2)  # 2 = Power off


# =============================================================================
# ALTERNATIVE: Direct NtShutdownSystem (less aggressive)
# =============================================================================


def fast_reboot():
    """
    Fast reboot using NtShutdownSystem directly.
    This is less aggressive than nuclear_reboot but still very fast.
    May show brief "Restarting" screen on some systems.
    """
    enable_privilege(SE_SHUTDOWN_PRIVILEGE)
    ntdll.NtShutdownSystem(1)


def fast_shutdown():
    """Fast shutdown using NtShutdownSystem directly."""
    enable_privilege(SE_SHUTDOWN_PRIVILEGE)
    ntdll.NtShutdownSystem(2)


# =============================================================================
# ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    # Check admin
    if not is_admin():
        print("ERROR: Must run as Administrator!")
        print("Right-click and select 'Run as administrator'")
        sys.exit(1)

    # Parse arguments
    args = [a.lower() for a in sys.argv[1:]]

    if "--test" in args or "-t" in args:
        print("=" * 60)
        print("NUCLEAR REBOOT - TEST MODE")
        print("=" * 60)
        print()
        print("This script will perform an IMMEDIATE system reboot.")
        print("There will be NO warning, NO 'Restarting' screen.")
        print("The system will simply reboot within 1-2 seconds.")
        print()
        print("To actually reboot, run without --test flag:")
        print("  python instant_reboot_nuclear.py")
        print()
        print("Privileges available:")
        print(f"  SE_SHUTDOWN_PRIVILEGE: {enable_privilege(SE_SHUTDOWN_PRIVILEGE)}")
        print(f"  SE_DEBUG_PRIVILEGE: {enable_privilege(SE_DEBUG_PRIVILEGE)}")
        print()
        print("Ready to reboot. Run without --test to execute.")
        sys.exit(0)

    if "--shutdown" in args or "-s" in args:
        print("Initiating NUCLEAR SHUTDOWN...")
        nuclear_shutdown()
    elif "--fast" in args or "-f" in args:
        print("Initiating FAST REBOOT (NtShutdownSystem)...")
        fast_reboot()
    else:
        # Default: Nuclear reboot
        print("Initiating NUCLEAR REBOOT...")
        nuclear_reboot()
