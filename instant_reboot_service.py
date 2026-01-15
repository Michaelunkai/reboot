"""
INSTANT REBOOT SERVICE
======================
A Windows service that intercepts shutdown/restart events and performs
immediate NtShutdownSystem calls to bypass the normal shutdown sequence.

This service:
1. Registers for SERVICE_CONTROL_SHUTDOWN notifications
2. When shutdown is detected, immediately calls NtShutdownSystem
3. Bypasses the "Restarting" screen and app-closing delays

Installation:
    python instant_reboot_service.py install
    python instant_reboot_service.py start

Removal:
    python instant_reboot_service.py stop
    python instant_reboot_service.py remove

Requires: pywin32 (pip install pywin32)
"""

import ctypes
import sys
import os
import time
import logging
from ctypes import wintypes

# Try to import pywin32 components
try:
    import win32serviceutil
    import win32service
    import win32event
    import servicemanager
    import win32api
    import win32con

    PYWIN32_AVAILABLE = True
except ImportError:
    PYWIN32_AVAILABLE = False
    print("WARNING: pywin32 not installed. Service functionality disabled.")
    print("Install with: pip install pywin32")

# =============================================================================
# NT SHUTDOWN FUNCTIONS
# =============================================================================

ntdll = ctypes.windll.ntdll

ntdll.RtlAdjustPrivilege.restype = wintypes.LONG
ntdll.RtlAdjustPrivilege.argtypes = [
    wintypes.ULONG,
    wintypes.BOOLEAN,
    wintypes.BOOLEAN,
    ctypes.POINTER(wintypes.BOOLEAN),
]

ntdll.NtShutdownSystem.restype = wintypes.LONG
ntdll.NtShutdownSystem.argtypes = [wintypes.ULONG]

SE_SHUTDOWN_PRIVILEGE = 19
ShutdownReboot = 1
ShutdownPowerOff = 2


def enable_shutdown_privilege():
    """Enable SeShutdownPrivilege"""
    previous_state = wintypes.BOOLEAN()
    status = ntdll.RtlAdjustPrivilege(
        SE_SHUTDOWN_PRIVILEGE, True, False, ctypes.byref(previous_state)
    )
    return status == 0


def instant_reboot():
    """Perform immediate reboot using NtShutdownSystem"""
    enable_shutdown_privilege()
    ntdll.NtShutdownSystem(ShutdownReboot)


def instant_poweroff():
    """Perform immediate power off using NtShutdownSystem"""
    enable_shutdown_privilege()
    ntdll.NtShutdownSystem(ShutdownPowerOff)


# =============================================================================
# WINDOWS SERVICE
# =============================================================================

if PYWIN32_AVAILABLE:

    class InstantRebootService(win32serviceutil.ServiceFramework):
        """
        Windows Service that intercepts shutdown events and performs instant reboot.
        """

        _svc_name_ = "InstantRebootService"
        _svc_display_name_ = "Instant Reboot Service"
        _svc_description_ = "Intercepts shutdown/restart events and performs immediate NtShutdownSystem calls"

        def __init__(self, args):
            win32serviceutil.ServiceFramework.__init__(self, args)
            self.stop_event = win32event.CreateEvent(None, 0, 0, None)
            self.running = True

            # Setup logging
            log_dir = os.path.join(
                os.environ.get("ProgramData", "C:\\ProgramData"), "InstantReboot"
            )
            if not os.path.exists(log_dir):
                os.makedirs(log_dir)

            logging.basicConfig(
                filename=os.path.join(log_dir, "service.log"),
                level=logging.INFO,
                format="%(asctime)s - %(levelname)s - %(message)s",
            )
            self.logger = logging.getLogger("InstantRebootService")

        def SvcStop(self):
            """Called when the service is stopped"""
            self.logger.info("Service stop requested")
            self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
            win32event.SetEvent(self.stop_event)
            self.running = False

        def SvcShutdown(self):
            """
            Called when the system is shutting down.
            This is where we intercept and perform instant reboot.
            """
            self.logger.info("SHUTDOWN EVENT RECEIVED - Performing instant reboot!")

            # Perform instant reboot immediately
            try:
                instant_reboot()
            except Exception as e:
                self.logger.error(f"Instant reboot failed: {e}")
                # Fallback: try again
                try:
                    enable_shutdown_privilege()
                    ntdll.NtShutdownSystem(ShutdownReboot)
                except:
                    pass

        def SvcDoRun(self):
            """Main service loop"""
            self.logger.info("Instant Reboot Service started")
            servicemanager.LogMsg(
                servicemanager.EVENTLOG_INFORMATION_TYPE,
                servicemanager.PYS_SERVICE_STARTED,
                (self._svc_name_, ""),
            )

            # Accept shutdown control
            self.ReportServiceStatus(win32service.SERVICE_RUNNING)

            # Main loop - wait for stop event
            while self.running:
                rc = win32event.WaitForSingleObject(self.stop_event, 5000)
                if rc == win32event.WAIT_OBJECT_0:
                    break

            self.logger.info("Instant Reboot Service stopped")

# =============================================================================
# ALTERNATIVE: Console Control Handler (for non-service use)
# =============================================================================

shutdown_triggered = False


def console_ctrl_handler(ctrl_type):
    """Handle console control events including shutdown"""
    global shutdown_triggered

    if ctrl_type == win32con.CTRL_SHUTDOWN_EVENT if PYWIN32_AVAILABLE else 6:
        if not shutdown_triggered:
            shutdown_triggered = True
            print("Shutdown event detected - performing instant reboot!")
            instant_reboot()
        return True

    return False


def install_console_handler():
    """Install console control handler to intercept shutdown"""
    if PYWIN32_AVAILABLE:
        win32api.SetConsoleCtrlHandler(console_ctrl_handler, True)
    else:
        # Use ctypes fallback
        kernel32 = ctypes.windll.kernel32
        HANDLER_ROUTINE = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_ulong)
        handler = HANDLER_ROUTINE(console_ctrl_handler)
        kernel32.SetConsoleCtrlHandler(handler, True)


# =============================================================================
# MAIN
# =============================================================================


def print_usage():
    print("""
INSTANT REBOOT SERVICE
======================

Usage:
    python instant_reboot_service.py install   - Install the service
    python instant_reboot_service.py start     - Start the service
    python instant_reboot_service.py stop      - Stop the service
    python instant_reboot_service.py remove    - Remove the service
    python instant_reboot_service.py restart   - Restart the service
    python instant_reboot_service.py debug     - Run in debug mode (console)
    python instant_reboot_service.py console   - Run as console app with shutdown handler

Requirements:
    pip install pywin32
    
The service intercepts system shutdown events and performs immediate
NtShutdownSystem calls to bypass the normal shutdown sequence.
""")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print_usage()
        sys.exit(0)

    if not PYWIN32_AVAILABLE:
        if sys.argv[1] in ["install", "start", "stop", "remove", "restart", "debug"]:
            print("ERROR: pywin32 is required for service functionality")
            print("Install with: pip install pywin32")
            sys.exit(1)
        elif sys.argv[1] == "console":
            print("Running in console mode with shutdown handler...")
            install_console_handler()
            print("Press Ctrl+C to exit")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                print("Exiting...")
        else:
            print_usage()
        sys.exit(0)

    if sys.argv[1] == "console":
        print("Running in console mode with shutdown handler...")
        install_console_handler()
        print("Shutdown events will trigger instant reboot")
        print("Press Ctrl+C to exit")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("Exiting...")
    else:
        win32serviceutil.HandleCommandLine(InstantRebootService)
