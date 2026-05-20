// CreateSingleProcess.cpp : このファイルには 'main' 関数が含まれています。プログラム実行の開始と終了がそこで行われます。
//

#include <windows.h>
#include <tlhelp32.h>
#include <iostream>

HWND g_hwnd = nullptr;
DWORD g_pid = 0;

BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM)
{
    // g_pidに対して一致するウィンドウ（ハンドル）を探す
    DWORD pid = 0;

    GetWindowThreadProcessId(hwnd, &pid);

    if (pid == g_pid && IsWindowVisible(hwnd))
    {
        g_hwnd = hwnd;
        return FALSE;
    }

    return TRUE;
}


int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        std::cout << "Usage: CreateSingleProcess.exe <exe path>\n";
        return 1;
    }

    wchar_t exePath[MAX_PATH];
    MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, exePath, MAX_PATH);

    wchar_t* exeName = wcsrchr(exePath, L'\\');

    if (exeName) exeName++;
    else exeName = exePath;

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    PROCESSENTRY32W pe = {};
    pe.dwSize = sizeof(pe);

    if (Process32FirstW(snapshot, &pe))
    {
        do
        {
            if (_wcsicmp(pe.szExeFile, exeName) == 0)
            {
                g_pid = pe.th32ProcessID;
                EnumWindows(EnumWindowsProc, 0);

                if (g_hwnd)
                {
                    ShowWindow(g_hwnd, SW_RESTORE);
                    SetForegroundWindow(g_hwnd);
                }

                CloseHandle(snapshot);
                return 0;
            }

        } while (Process32NextW(snapshot, &pe));
    }

    CloseHandle(snapshot);

    wchar_t dir[MAX_PATH];
    wcscpy_s(dir, exePath);

    wchar_t* p = wcsrchr(dir, L'\\');

    if (p) *p = 0;

    STARTUPINFOW si = {};
    PROCESS_INFORMATION pi = {};

    si.cb = sizeof(si);

    CreateProcessW(
        exePath,
        nullptr,
        nullptr,
        nullptr,
        FALSE,
        0,
        nullptr,
        dir,
        &si,
        &pi);

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    return 0;
}

// プログラムの実行: Ctrl + F5 または [デバッグ] > [デバッグなしで開始] メニュー
// プログラムのデバッグ: F5 または [デバッグ] > [デバッグの開始] メニュー

// 作業を開始するためのヒント: 
//    1. ソリューション エクスプローラー ウィンドウを使用してファイルを追加/管理します 
//   2. チーム エクスプローラー ウィンドウを使用してソース管理に接続します
//   3. 出力ウィンドウを使用して、ビルド出力とその他のメッセージを表示します
//   4. エラー一覧ウィンドウを使用してエラーを表示します
//   5. [プロジェクト] > [新しい項目の追加] と移動して新しいコード ファイルを作成するか、[プロジェクト] > [既存の項目の追加] と移動して既存のコード ファイルをプロジェクトに追加します
//   6. 後ほどこのプロジェクトを再び開く場合、[ファイル] > [開く] > [プロジェクト] と移動して .sln ファイルを選択します
