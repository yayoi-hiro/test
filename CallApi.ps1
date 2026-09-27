# C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exeで実行

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies "System.Windows.Forms.dll" @"
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class MessageWindow : NativeWindow
{
    public const int WM_RESULT = 0x8001;

    public MessageWindow()
    {
        CreateHandle(new CreateParams());
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_RESULT)
        {
            Console.WriteLine("結果を受信しました");
            Console.WriteLine("wParam = " + m.WParam.ToInt64());
            Console.WriteLine("lParam = " + m.LParam.ToInt64());
        }

        base.WndProc(ref m);
    }
}

[StructLayout(LayoutKind.Sequential)]
public struct Request
{
    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 20)]
    public byte[] Name;

    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 10)]
    public byte[] Color;
}

public static class NativeMethods
{
    [DllImport("ApiDll.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Start(ref Request request, IntPtr hWnd);
}
"@

function ConvertTo-ByteArrayString($Size, $Text)
{
    $array = New-Object byte[] $Size
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
    [Array]::Copy($bytes, $array, [Math]::Min($bytes.Length, $array.Length))
    return $array
}

function ConvertFrom-ByteArrayString($ByteArray)
{
    return [System.Text.Encoding]::ASCII.GetString($ByteArray).TrimEnd([char]0)
}


# メッセージ受信用Windowを作成
$window = New-Object MessageWindow

# DLLへ渡す構造体
$request = New-Object Request

$request.Name = ConvertTo-ByteArrayString 20 "ABC"
$request.Color = ConvertTo-ByteArrayString 10 "RED"

Write-Host "Name  = $(ConvertFrom-ByteArrayString $request.Name)"
Write-Host "Color = $(ConvertFrom-ByteArrayString $request.Color)"

# HWNDをDLLへ渡して処理開始
$result = [NativeMethods]::Start([ref]$request, $window.Handle)

Write-Host "Start() = $result"
Write-Host "HWND = 0x$($window.Handle.ToInt64().ToString('X'))"

# メッセージを待つ
while ($true) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 10
}