Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Win32
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern IntPtr WindowFromPoint(POINT pt);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(
        IntPtr hWnd,
        StringBuilder lpString,
        int nMaxCount);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetClassName(
        IntPtr hWnd,
        StringBuilder lpClassName,
        int nMaxCount);
}
"@

while ($true)
{
    [Win32+POINT]$pt = New-Object Win32+POINT
    [Win32]::GetCursorPos([ref]$pt) | Out-Null

    $hwnd = [Win32]::WindowFromPoint($pt)

    $title = New-Object System.Text.StringBuilder 256
    $class = New-Object System.Text.StringBuilder 256

    [Win32]::GetWindowText($hwnd, $title, $title.Capacity) | Out-Null
    [Win32]::GetClassName($hwnd, $class, $class.Capacity) | Out-Null

    Clear-Host

    Write-Host "HWND  : $hwnd"
    Write-Host "Class : $class"
    Write-Host "Title : $title"
    Write-Host "Pos   : ($($pt.X), $($pt.Y))"

    Start-Sleep -Seconds 1
}