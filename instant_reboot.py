"""
INSTANT REBOOT - Zero-Delay Windows Reboot Utility
===================================================
Performs an immediate system reboot using NtShutdownSystem.
No delays, no "Restarting" screen, no app-preventing-shutdown dialogs.

This is the core reboot mechanism used by the instant reboot system.
Run as Administrator for proper functionality.

Usage:
    python instant_reboot.py [--shutdown|--poweroff]

    Default: Reboot
    --shutdown: Shutdown without reboot
    --poweroff: Power off
"""

import ctypes
import sys
from ctypes import wintypes

# =============================================================================
# NT SHUTDOWN ACTIONS
# =============================================================================
ShutdownNoReboot = 0  # Shutdown without reboot
ShutdownReboot = 1  # Reboot
ShutdownPowerOff = 2  # Power off

# =============================================================================
# DLL HANDLES
# =============================================================================
ntdll = ctypes.windll.ntdll

# =============================================================================
# FUNCTION PROTOTYPES
# =============================================================================
ntdll.RtlAdjustPrivilege.restype = wintypes.LONG
ntdll.RtlAdjustPrivilege.argtypes = [
    wintypes.ULONG,
    wintypes.BOOLEAN,
    wintypes.BOOLEAN,
    ctypes.POINTER(wintypes.BOOLEAN),
]

ntdll.NtShutdownSystem.restype = wintypes.LONG
ntdll.NtShutdownSystem.argtypes = [wintypes.ULONG]

# =============================================================================
# PRIVILEGE CONSTANTS
# =============================================================================
SE_SHUTDOWN_PRIVILEGE = 19

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================


def enable_shutdown_privilege():
    """Enable SeShutdownPrivilege using RtlAdjustPrivilege (fastest method)"""
    previous_state = wintypes.BOOLEAN()
    status = ntdll.RtlAdjustPrivilege(
        SE_SHUTDOWN_PRIVILEGE,
        True,  # Enable
        False,  # Not thread-only
        ctypes.byref(previous_state),
    )
    return status == 0


def instant_reboot():
    """Perform an immediate system reboot - no delays, no prompts"""
    enable_shutdown_privilege()
    ntdll.NtShutdownSystem(ShutdownReboot)


def instant_shutdown():
    """Perform an immediate system shutdown - no delays, no prompts"""
    enable_shutdown_privilege()
    ntdll.NtShutdownSystem(ShutdownNoReboot)


def instant_poweroff():
    """Perform an immediate system power off - no delays, no prompts"""
    enable_shutdown_privilege()
    ntdll.NtShutdownSystem(ShutdownPowerOff)


# =============================================================================
# ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in ("--shutdown", "-s", "/s"):
            instant_shutdown()
        elif arg in ("--poweroff", "-p", "/p"):
            instant_poweroff()
        else:
            instant_reboot()
    else:
        instant_reboot()
