# ===== Win32 API =====
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")]
  public static extern bool MoveWindow(
    IntPtr hWnd, int X, int Y, int W, int H, bool repaint);
    
  [DllImport("user32.dll")]
    public static extern bool GetWindowRect(
    IntPtr hWnd, out RECT lpRect);
   
   public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

# ===== 設定（ここだけ編集）=====
$apps = @(
    @{ Type="Exe";      Path="C:\Users\miyuj\Desktop\rightsout.exe"; X=5 ;Y=226 ;W=486 ;H=510 },
    @{ Type="Explorer"; Path="C:\Users\miyuj\Desktop\新しいフォルダー"; X=1154 ;Y=98 ;W=650 ;H=819 }
    @{ Type="Explorer"; Path="C:\Users\miyuj\Desktop\プログラミング\★作成物\powershell\ウィンドウ制御";  X=484 ;Y=96 ;W=678 ;H=836 }
)


# ===== 共通：ウィンドウ移動 =====
function Move-AppWindow($hwnd, $app)
{
    if ($app.W -eq 0 -or $app.H -eq 0){
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null

    $app.W = $rect.Right - $rect.Left
    $app.H = $rect.Bottom - $rect.Top
    }
    [Win32]::MoveWindow(
        $hwnd,
        $app.X, $app.Y,
        $app.W, $app.H,
        $true)
}

# ===== EXE待機 =====
function Wait-ExeWindow($path)
{
    $name = [System.IO.Path]::GetFileNameWithoutExtension($path)

    while ($true)
    {
        $p = Get-Process $name -ErrorAction SilentlyContinue |
             Where-Object {$_.MainWindowHandle -ne 0} |
             Select-Object -First 1

        if ($p) { return $p.MainWindowHandle }
        Start-Sleep -Milliseconds 300
    }
}

# ===== Explorer待機 =====
function Wait-ExplorerWindow($folder)
{
    $shell = New-Object -ComObject Shell.Application

    while ($true)
    {
        foreach ($w in $shell.Windows())
        {
            try {
                if ($w.Document -and
                    $w.Document.Folder.Self.Path -eq $folder)
                {
                    return [IntPtr]$w.HWND
                }
            } catch {}
        }
        Start-Sleep -Milliseconds 300
    }
}

# ===== 起動 =====
foreach ($app in $apps)
{
    if ($app.Type -eq "Exe") {
        Start-Process $app.Path
    }
    elseif ($app.Type -eq "Explorer") {
        Start-Process explorer.exe $app.Path
    }
}

# ===== 配置 =====
foreach ($app in $apps)
{
    if ($app.Type -eq "Exe") {
        $hwnd = Wait-ExeWindow $app.Path
    }
    elseif ($app.Type -eq "Explorer") {
        $hwnd = Wait-ExplorerWindow $app.Path
    }

    Move-AppWindow $hwnd $app
}