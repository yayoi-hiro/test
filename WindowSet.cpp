#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>

wchar_t* g_title;
int g_x, g_y, g_w, g_h;
int g_mode = 0; // 0=列挙, 1=移動

void usage()
{
    wprintf(L"Usage:\n");
    wprintf(L"  WindowSet.exe -a : ウィンドウ列挙\n");
    wprintf(L"  WindowSet.exe \"title\" x y w h : ウィンドウ移動\n");
}

BOOL CALLBACK EnumProc(HWND hWnd, LPARAM)
{
    wchar_t buf[256];
    GetWindowText(hWnd, buf, 256);

    if (hWnd == GetConsoleWindow()) return TRUE;
    if (!IsWindowVisible(hWnd)) return TRUE;

    if (g_mode == 0)
    {
        if (IsIconic(hWnd)) return TRUE;

        if (wcslen(buf) > 0)
        {
            RECT r;
            GetWindowRect(hWnd, &r);

            int x = r.left;
            int y = r.top;
            int w = r.right - r.left;
            int h = r.bottom - r.top;

            wprintf(L"\"%s\" %d %d %d %d\n", buf, x, y, w, h);
        }
        return TRUE;
    }

    if (wcsstr(buf, g_title) && !wcsstr(buf, L"WindowSet.exe"))
    {
        wprintf(L"HIT: %p : %s\n", hWnd, buf);
        MoveWindow(hWnd, g_x, g_y, g_w, g_h, TRUE);
        return FALSE;
    }

    return TRUE;
}

int wmain(int argc, wchar_t* argv[])
{
    _setmode(_fileno(stdout), _O_U16TEXT);

    // -a → 列挙モード
    if (argc == 2 && wcscmp(argv[1], L"-a") == 0)
    {
        g_mode = 0;
        wprintf(L"// title x y w h\n");
        EnumWindows(EnumProc, 0);
        return 0;
    }

    // 引数が正しくない場合
    if (argc != 6)
    {
        usage();
        return 1;
    }

    // 移動モード
    g_mode = 1;

    g_title = argv[1];
    g_x = _wtoi(argv[2]);
    g_y = _wtoi(argv[3]);
    g_w = _wtoi(argv[4]);
    g_h = _wtoi(argv[5]);

    EnumWindows(EnumProc, 0);

    return 0;
}