/*
 * NUCLEAR REBOOT - System Tray Application
 * =========================================
 * 
 * Sits in the system tray. Left-click = instant reboot.
 * 
 * Compile with:
 *   csc /out:NuclearRebootTray.exe /target:winexe /r:System.Windows.Forms.dll /r:System.Drawing.dll NuclearRebootTray.cs
 * 
 * Usage:
 *   NuclearRebootTray.exe    # Starts in system tray
 *   Left-click tray icon     # Instant reboot
 *   Right-click              # Menu with options
 */

using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

class NuclearRebootTray : Form
{
    // ==========================================================================
    // NUCLEAR SHUTDOWN API
    // ==========================================================================
    
    const uint OptionShutdownSystem = 6;
    const uint STATUS_ASSERTION_FAILURE = 0xC0000420;
    const ulong SE_SHUTDOWN_PRIVILEGE = 19;
    const ulong SE_DEBUG_PRIVILEGE = 20;
    const int ShutdownReboot = 1;
    const int ShutdownPowerOff = 2;
    
    [DllImport("ntdll.dll")]
    static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, out bool PreviousValue);
    
    [DllImport("ntdll.dll")]
    static extern uint NtRaiseHardError(uint ErrorStatus, uint NumberOfParameters, uint UnicodeStringParameterMask,
        IntPtr Parameters, uint ValidResponseOptions, out uint Response);
    
    [DllImport("ntdll.dll")]
    static extern int NtShutdownSystem(int Action);
    
    [DllImport("shell32.dll")]
    static extern bool IsUserAnAdmin();
    
    // ==========================================================================
    // TRAY ICON
    // ==========================================================================
    
    private NotifyIcon trayIcon;
    private ContextMenuStrip trayMenu;
    
    public NuclearRebootTray()
    {
        // Hide the form
        this.WindowState = FormWindowState.Minimized;
        this.ShowInTaskbar = false;
        this.Visible = false;
        
        // Create context menu
        trayMenu = new ContextMenuStrip();
        trayMenu.Items.Add("⚡ Instant Reboot", null, OnReboot);
        trayMenu.Items.Add("⏻ Instant Shutdown", null, OnShutdown);
        trayMenu.Items.Add(new ToolStripSeparator());
        trayMenu.Items.Add("❌ Exit", null, OnExit);
        
        // Create tray icon
        trayIcon = new NotifyIcon();
        trayIcon.Text = "Nuclear Reboot - Left-click to reboot instantly";
        trayIcon.Icon = CreateIcon();
        trayIcon.ContextMenuStrip = trayMenu;
        trayIcon.Visible = true;
        
        // Left-click = instant reboot
        trayIcon.MouseClick += (s, e) => {
            if (e.Button == MouseButtons.Left)
            {
                DoNuclearReboot();
            }
        };
        
        // Show balloon tip
        trayIcon.ShowBalloonTip(3000, "Nuclear Reboot Active", 
            "Left-click for instant reboot\nRight-click for menu", ToolTipIcon.Info);
    }
    
    private Icon CreateIcon()
    {
        // Create a simple red power icon
        Bitmap bmp = new Bitmap(16, 16);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            
            // Draw red circle with power symbol
            using (Pen pen = new Pen(Color.Red, 2))
            {
                g.DrawEllipse(pen, 2, 2, 11, 11);
                g.DrawLine(pen, 7, 0, 7, 6);
            }
        }
        return Icon.FromHandle(bmp.GetHicon());
    }
    
    // ==========================================================================
    // SHUTDOWN METHODS
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
        uint status = NtRaiseHardError(STATUS_ASSERTION_FAILURE, 0, 0, IntPtr.Zero, OptionShutdownSystem, out response);
        
        if (status != 0)
        {
            NtShutdownSystem(ShutdownReboot);
        }
    }
    
    static void DoNuclearShutdown()
    {
        EnablePrivileges();
        
        uint response;
        uint status = NtRaiseHardError(STATUS_ASSERTION_FAILURE, 0, 0, IntPtr.Zero, OptionShutdownSystem, out response);
        
        if (status != 0)
        {
            NtShutdownSystem(ShutdownPowerOff);
        }
    }
    
    // ==========================================================================
    // EVENT HANDLERS
    // ==========================================================================
    
    private void OnReboot(object sender, EventArgs e)
    {
        DoNuclearReboot();
    }
    
    private void OnShutdown(object sender, EventArgs e)
    {
        DoNuclearShutdown();
    }
    
    private void OnExit(object sender, EventArgs e)
    {
        trayIcon.Visible = false;
        Application.Exit();
    }
    
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        this.Visible = false;
    }
    
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            trayIcon.Dispose();
        }
        base.Dispose(disposing);
    }
    
    // ==========================================================================
    // MAIN
    // ==========================================================================
    
    [STAThread]
    static void Main()
    {
        if (!IsUserAnAdmin())
        {
            MessageBox.Show("Must run as Administrator!\n\nRight-click and select 'Run as administrator'",
                "Nuclear Reboot", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new NuclearRebootTray());
    }
}
