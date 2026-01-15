# Instant Reboot for Windows 11

<!-- gitit-sync: 2026-01-15 14:54:47.629858 -->

A comprehensive solution to make Windows 11 restarts/reboots happen **INSTANTLY** - no delays, no "Restarting" screen, no waiting.

## 🚀 NUCLEAR REBOOT (RECOMMENDED)

**GUARANTEED instant reboot with NO "Restarting" screen.** Uses `NtRaiseHardError` which triggers kernel-level shutdown that Windows CANNOT intercept.

### Quick Install

```powershell
# Run as Administrator
.\setup_nuclear_reboot.ps1 -Install
```

### How to Use After Installation

| Method | How |
|--------|-----|
| **Desktop** | Double-click "Nuclear Reboot" icon |
| **Keyboard** | Press `Ctrl+Alt+R` |
| **Start Menu** | Search "Nuclear Reboot" |
| **System Tray** | Run `NuclearRebootTray.exe`, left-click tray icon |
| **Command Line** | `NuclearReboot.exe` |
| **PowerShell** | `instant_reboot_nuclear.ps1` |

### What Gets Installed

| File | Purpose |
|------|---------|
| `NuclearReboot.exe` | Standalone instant reboot (no dependencies) |
| `NuclearRebootTray.exe` | System tray app - left-click to reboot |
| `instant_reboot_nuclear.ps1` | PowerShell version |
| Desktop/Start shortcuts | Easy access |
| Keyboard hotkey | Ctrl+Alt+R triggers instant reboot |

## The Problem

Windows 11's normal shutdown/restart takes 10-30+ seconds because it:
1. Broadcasts `WM_QUERYENDSESSION` to all applications
2. Waits for apps to respond (up to 5 seconds each)
3. Shows "This app is preventing shutdown" dialogs
4. Waits for services to stop
5. **Displays the annoying "Restarting" screen**
6. Finally performs the actual reboot

## The Solution: Nuclear Reboot

We use `NtRaiseHardError` with `OptionShutdownSystem` (option 6) which:
- Triggers a **kernel-level critical shutdown**
- Bypasses ALL Windows shutdown UI
- **NO "Restarting" screen is possible**
- System reboots within **1-2 seconds**

This is the same mechanism Windows uses for unrecoverable errors - there is no way for Windows to show any UI before reboot.

## Technical Details

### Nuclear Method (NtRaiseHardError)

```c
// Enable privileges
RtlAdjustPrivilege(SE_SHUTDOWN_PRIVILEGE, TRUE, FALSE, &oldValue);
RtlAdjustPrivilege(SE_DEBUG_PRIVILEGE, TRUE, FALSE, &oldValue);

// Trigger kernel-level shutdown - NO UI possible
NtRaiseHardError(
    STATUS_ASSERTION_FAILURE,  // Any critical error
    0, 0, NULL,
    OptionShutdownSystem,      // 6 = immediate shutdown
    &response
);
```

### Fallback Method (NtShutdownSystem)

If `NtRaiseHardError` doesn't trigger (rare), falls back to:

```c
NtShutdownSystem(ShutdownReboot);  // 1 = reboot
```

## Alternative: Original Method (Less Aggressive)

The original `setup_instant_reboot.ps1` uses IFEO hooks and `NtShutdownSystem`. This is less aggressive but may still show brief "Restarting" screen on some systems.

```powershell
.\setup_instant_reboot.ps1 -Install     # Original method
.\setup_instant_reboot.ps1 -Uninstall   # Remove
```

## All Components

| File | Purpose |
|------|---------|
| `setup_nuclear_reboot.ps1` | **RECOMMENDED** - Nuclear reboot installer |
| `NuclearReboot.exe` | Standalone nuclear reboot EXE |
| `NuclearRebootTray.exe` | System tray app |
| `NuclearReboot.cs` | C# source code |
| `instant_reboot_nuclear.py` | Python nuclear reboot |
| `instant_reboot_nuclear.ps1` | PowerShell nuclear reboot |
| `setup_instant_reboot.ps1` | Original IFEO-based installer |
| `instant_reboot.py` | Original Python script |
| `shutdown_hook.ps1` | IFEO hook script |
| `apply_instant_reboot.reg` | Registry optimizations |
| `restore_default_shutdown.reg` | Restore defaults |

## ⚠️ Warning

**DATA LOSS RISK**: Nuclear reboot does NOT:
- Prompt applications to save data
- Wait for file writes to complete
- Properly close database connections
- Show any warning or confirmation

**ALWAYS SAVE YOUR WORK FIRST!**

This is designed for users who:
- Need the absolute fastest reboot possible
- Accept the risk of data loss in unsaved applications
- **NEVER want to see the "Restarting" screen again**

## Uninstallation

```powershell
# Nuclear reboot
.\setup_nuclear_reboot.ps1 -Uninstall

# Original method
.\setup_instant_reboot.ps1 -Uninstall
```

## Troubleshooting

### "Access Denied" Error
Run as Administrator. These functions require elevation.

### Hotkey (Ctrl+Alt+R) Not Working
The hotkey shortcut must remain on your desktop. Don't delete "Nuclear Reboot Hotkey.lnk".

### Still Seeing "Restarting" Screen
You're probably using the original method. Switch to Nuclear:
```powershell
.\setup_instant_reboot.ps1 -Uninstall
.\setup_nuclear_reboot.ps1 -Install
```

## License

MIT License - Use at your own risk.

<!-- gitit-sync: 2026-01-15 15:24:52.501215 -->
