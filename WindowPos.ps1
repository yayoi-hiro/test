Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class WindowLister
{
    const double SCALE = 1.25;

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc f, IntPtr p);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] static extern int  GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] static extern int  GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);

    public struct RECT
    {
        public int Left, Top, Right, Bottom;
    }

    static int S(double v) { return (int)Math.Round(v * SCALE); }

    static string GetProcess(uint pid)
    {
        try { return Process.GetProcessById((int)pid).ProcessName; }
        catch { return ""; }
    }

    public static void List()
    {
        EnumWindows(delegate (IntPtr hWnd, IntPtr lParam)
        {
            if (!IsWindowVisible(hWnd) || IsIconic(hWnd))
                return true;

            int len = GetWindowTextLength(hWnd);
            if (len == 0)
                return true;

            var sb = new StringBuilder(len + 1);
            GetWindowText(hWnd, sb, sb.Capacity);

            RECT r;
            GetWindowRect(hWnd, out r);

            int w = r.Right - r.Left;
            int h = r.Bottom - r.Top;

            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);

            Console.WriteLine(
                sb + " (" + GetProcess(pid) + ")" +
                " X=" + S(r.Left) +
                "; Y=" + S(r.Top) +
                "; W=" + S(w) +
                "; H=" + S(h)
            );

            return true;
        }, IntPtr.Zero);
    }
}
"@

[WindowLister]::List()
Read-Host "Press Enter to continue"