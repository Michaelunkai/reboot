# Instant Reboot for Windows 11

<!-- gitit-sync: 2026-01-15 14:54:47.629858 -->

A comprehensive solution to make Windows 11 restarts/reboots happen **immediately** - no delays, no "Restarting" screen, no "This app is preventing shutdown" dialogs.

## The Problem

Windows 11's normal shutdown/restart sequence:
1. Broadcasts `WM_QUERYENDSESSION` to all applications
2. Waits for apps to respond (up to 5 seconds each)
3. Shows "This app is preventing shutdown" if apps don't close
4. Waits for services to stop (up to 5 seconds)
5. Displays the "Restarting" screen
6. Finally performs the actual reboot

This can take 10-30+ seconds even on fast hardware.

## The Solution

This project bypasses the entire Windows shutdown sequence by calling `NtShutdownSystem` directly - the same kernel function Windows uses internally, but without all the waiting.

### Components

| File | Purpose |
|------|---------|
| `setup_instant_reboot.ps1` | Main installer/uninstaller script |
| `instant_reboot.py` | Python script using NtShutdownSystem |
| `instant_reboot_service.py` | Windows service for shutdown interception |
| `shutdown_hook.ps1` | IFEO hook to intercept shutdown.exe calls |
| `apply_instant_reboot.reg` | Registry file for manual application |
| `restore_default_shutdown.reg` | Restore default Windows behavior |

## Quick Start

### Option 1: Full Installation (Recommended)

```powershell
# Run as Administrator
.\setup_instant_reboot.ps1 -Install
```

This will:
- Apply aggressive shutdown timeout registry settings
- Disable Fast Startup (for true full restarts)
- Install instant reboot scripts to `C:\Program Files\InstantReboot`
- Configure IFEO to intercept `shutdown.exe` calls
- Add install directory to system PATH

### Option 2: Registry Only (Safest)

```powershell
# Run as Administrator
.\setup_instant_reboot.ps1 -RegistryOnly
```

Only applies registry optimizations without installing any scripts. This is safer but less effective.

### Option 3: Manual Registry Application

Double-click `apply_instant_reboot.reg` to apply registry settings manually.

## Usage

After installation:

```powershell
# Instant reboot
instant_reboot.ps1

# Instant shutdown (power off)
instant_reboot.ps1 -Shutdown

# Instant power off
instant_reboot.ps1 -PowerOff
```

Or use Python:

```bash
python instant_reboot.py           # Reboot
python instant_reboot.py --shutdown  # Shutdown
python instant_reboot.py --poweroff  # Power off
```

## How It Works

### 1. Registry Optimizations

```registry
AutoEndTasks = 1          ; Force close apps without prompting
WaitToKillAppTimeout = 1000   ; 1 second timeout for apps
HungAppTimeout = 1000         ; 1 second to consider app hung
WaitToKillServiceTimeout = 1000 ; 1 second timeout for services
```

### 2. NtShutdownSystem

The core of instant reboot uses the undocumented NT kernel function:

```python
ntdll.RtlAdjustPrivilege(19, True, False, byref(previous))  # Enable SeShutdownPrivilege
ntdll.NtShutdownSystem(1)  # 1 = Reboot
```

This bypasses:
- Application close notifications
- Service shutdown sequence
- "Restarting" screen
- All Windows shutdown UI

### 3. Image File Execution Options (IFEO)

The installer configures IFEO to intercept `shutdown.exe` calls:

```registry
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\shutdown.exe
Debugger = "powershell.exe ... shutdown_hook.ps1"
```

When any program calls `shutdown.exe`, our hook intercepts it and performs instant shutdown instead.

### 4. Windows Service (Optional)

`instant_reboot_service.py` creates a Windows service that:
- Registers for `SERVICE_CONTROL_SHUTDOWN` notifications
- When Windows initiates shutdown, immediately calls `NtShutdownSystem`
- Requires `pywin32`: `pip install pywin32`

## What Gets Intercepted

| Shutdown Source | Intercepted? | Notes |
|-----------------|--------------|-------|
| Start Menu → Restart | ✅ Yes | Via IFEO hook |
| `shutdown /r /t 0` | ✅ Yes | Via IFEO hook |
| Ctrl+Alt+Del → Restart | ✅ Yes | Via IFEO hook |
| `ExitWindowsEx()` API | ⚠️ Partial | Registry timeouts help |
| Power button | ⚠️ Partial | Needs additional config |
| BSOD reboot | ❌ No | Kernel-level, cannot intercept |

## Uninstallation

```powershell
# Run as Administrator
.\setup_instant_reboot.ps1 -Uninstall
```

Or manually:
1. Double-click `restore_default_shutdown.reg`
2. Delete `C:\Program Files\InstantReboot`
3. Remove IFEO key: `reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\shutdown.exe" /f`

## ⚠️ Warnings

**DATA LOSS RISK**: Instant shutdown does not:
- Prompt applications to save data
- Wait for file writes to complete
- Properly close database connections
- Flush disk caches (though Windows does this automatically)

**USE CAREFULLY**: Always save your work before using instant reboot. This is designed for scenarios where:
- You need the fastest possible reboot
- You're okay with potential data loss in open applications
- You want to avoid the "Restarting" screen entirely

## Power Button Configuration

To make the physical power button trigger instant reboot:

1. Open Control Panel → Power Options → Choose what the power buttons do
2. Set "When I press the power button" to "Do nothing"
3. Create a scheduled task triggered by Event ID 42 (power button press) in System log
4. Task action: `powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\InstantReboot\instant_reboot.ps1"`

Or use the advanced ACPI power button interception (requires additional driver setup).

## Technical Details

### Shutdown Actions

| Value | Action |
|-------|--------|
| 0 | ShutdownNoReboot (shutdown without reboot) |
| 1 | ShutdownReboot (reboot) |
| 2 | ShutdownPowerOff (power off) |

### Required Privileges

- `SeShutdownPrivilege` (privilege ID 19) - Required for all shutdown operations
- Administrator rights - Required for privilege elevation

### API Functions Used

- `ntdll.dll!RtlAdjustPrivilege` - Enable shutdown privilege
- `ntdll.dll!NtShutdownSystem` - Perform shutdown/reboot
- `user32.dll!ExitWindowsEx` - Alternative shutdown method (with EWX_FORCE)

## Troubleshooting

### "Access Denied" Error
Run as Administrator. The shutdown privilege requires elevation.

### Reboot Not Instant
1. Verify registry settings were applied (check with regedit)
2. Ensure IFEO hook is configured
3. Try running `instant_reboot.ps1` directly to test

### IFEO Hook Not Working
Some security software may block IFEO modifications. Check your antivirus settings.

### Service Won't Install
Install pywin32: `pip install pywin32`
Run `python instant_reboot_service.py install` as Administrator.

## License

MIT License - Use at your own risk.

## Credits

Based on research into Windows shutdown internals and the `NtShutdownSystem` API.
Inspired by the need for instant reboots without the Windows "Restarting" ceremony.

<!-- gitit-sync: 2026-01-15 15:18:07.313325 -->

<!-- gitit-sync: 2026-01-15 15:21:03.669515 -->
