#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <windows.h>

std::string sourceDir;
std::string listFile;
std::string searchTargetDir;
std::string backupDir;
int backupMode;
bool useDryRun;

std::string ReadIniString(
    const std::string& iniFile,
    const std::string& section,
    const std::string& key,
    const std::string& defaultValue = "")
{
    char buffer[4096] = {};

    GetPrivateProfileStringA(
        section.c_str(),
        key.c_str(),
        defaultValue.c_str(),
        buffer,
        sizeof(buffer),
        iniFile.c_str());

    return std::string(buffer);
}

int ReadIniInt(
    const std::string& iniFile,
    const std::string& section,
    const std::string& key,
    int defaultValue = 0)
{
    return GetPrivateProfileIntA(
        section.c_str(),
        key.c_str(),
        defaultValue,
        iniFile.c_str());
}


// --- パス・ファイル操作ユーティリティ ---
namespace PathUtils {
    std::string getFileName(const std::string& path) {
        size_t lastSlash = path.find_last_of("\\/");
        return (lastSlash == std::string::npos) ? path : path.substr(lastSlash + 1);
    }

    std::string getParentPath(const std::string& path) {
        size_t lastSlash = path.find_last_of("\\/");
        return (lastSlash == std::string::npos) ? "" : path.substr(0, lastSlash);
    }

    std::string InsertBeforeExtension(const std::string& path, const std::string& text)
    {
        size_t slashPos = path.find_last_of("/\\");
        size_t dotPos = path.find_last_of('.');

        // 拡張子がない、または '.' がディレクトリ名にある場合
        if (dotPos == std::string::npos ||
            (slashPos != std::string::npos && dotPos < slashPos))
        {
            return path + text;
        }

        return path.substr(0, dotPos) + text + path.substr(dotPos);
    }

    bool exists(const std::string& path) {
        return GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES;
    }

    bool MoveFileOrSimurate(const std::string& src, const std::string& dst) {
        if (useDryRun)
        {
            // 実行なし
            return true;
        }
        else {
            // 実際に実行
            return MoveFileA(src.c_str(), dst.c_str()) != FALSE;
        }
    }

    bool CreateDirectoryOrSimulate(const std::string& path) {
        if (useDryRun)
        {
            // 実行なし
            return true;
        }
        else {
            // 実際に実行
            return CreateDirectoryA(path.c_str(), NULL) != FALSE;
        }
    }

    void createDirectories(std::string path) {
        std::string current;
        std::stringstream ss(path);
        std::string item;
        while (std::getline(ss, item, '\\')) {
            if (item.empty()) { // ドライブレター直後の空文字対応
                current += "\\";
                continue;
            }
            current += item + "\\";
            PathUtils::CreateDirectoryOrSimulate(current.c_str());
        }
    }


}

// --- 業務ロジック関数 ---

// バックアップ作成
void createBackup(const std::string& filePath) {
    auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::tm tm;
    localtime_s(&tm, &now);

    std::ostringstream oss;
    oss << "_bak" << std::put_time(&tm, "%Y%m%d%H%M%S");
    std::string backupFile = PathUtils::InsertBeforeExtension(filePath, oss.str());


    if (PathUtils::MoveFileOrSimurate(filePath.c_str(), backupFile.c_str())) {
        std::cout << "[Backup] " << PathUtils::getFileName(filePath) << " をリネーム退避しました。\n";
    }
    else
    {
        std::cerr << "[Error] バックアップ作成失敗 : "
            << PathUtils::getFileName(filePath)
            << GetLastError() << ")\n";
    }
}

void createBackupToDirectory(const std::string& filePath) {
    if (backupDir == "") {
        auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        std::tm tm;
        localtime_s(&tm, &now);

        std::ostringstream oss;
        oss << "bak_" << std::put_time(&tm, "%Y%m%d%H%M%S");

        // カレントディレクトリにバックアップフォルダを作成
        backupDir = oss.str();
        PathUtils::CreateDirectoryOrSimulate(backupDir.c_str());
    }
    std::string dst = backupDir + "\\" + PathUtils::getFileName(filePath);

    if (PathUtils::MoveFileOrSimurate(filePath.c_str(), dst.c_str())) {
        std::cout << "[Backup] " << PathUtils::getFileName(filePath) << " を別フォルダに退避しました。\n";
    }
    else
    {
        std::cout << "[Error] バックアップ失敗 : "
            << PathUtils::getFileName(filePath)
            << " (Error=" << GetLastError() << ")\n";
    }
}

// フォルダ作成を伴う移動
bool moveFileToDest(const std::string& src, const std::string& dest) {
    // 宛先ファイルが存在するならバックアップ作成
    if (PathUtils::exists(dest)) {
        switch (backupMode) {
        case 1:
            break;
        case 2:
            createBackup(dest);
            break;
        default:
            createBackupToDirectory(dest);
            break;
        }
    }
    // 宛先ファイルが存在しないなら親フォルダがあることを保証
    else {
        std::string destFolder = PathUtils::getParentPath(dest);
        if (!PathUtils::exists(destFolder)) {
            PathUtils::createDirectories(destFolder);
        }
    }

    if (PathUtils::MoveFileOrSimurate(src.c_str(), dest.c_str())) {
        std::cout << "-> 移動完了: " << dest << "\n";
        return true;
    }
    std::cerr << "-> [Error] 移動失敗: " << GetLastError() << "\n";
    return false;
}

// 再帰検索
std::string findInDirectory(const std::string& root, const std::string& targetName) {
    std::string searchPattern = root + "\\*";
    WIN32_FIND_DATAA data;
    HANDLE hFind = FindFirstFileA(searchPattern.c_str(), &data);

    if (hFind == INVALID_HANDLE_VALUE) return "";

    std::string foundPath = "";
    do {
        std::string name = data.cFileName;
        if (name == "." || name == "..") continue;

        std::string fullPath = root + "\\" + name;
        if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            foundPath = findInDirectory(fullPath, targetName);
        }
        else if (name == targetName) {
            foundPath = fullPath;
            return foundPath;
        }

        if (!foundPath.empty()) break;
    } while (FindNextFileA(hFind, &data));

    FindClose(hFind);
    return foundPath;
}

void searchMove(std::string filename, std::string srcPath, std::unordered_map<std::string, std::string>& historyTable) {

    // 履歴照会
    auto it = historyTable.find(filename);
    if (it != historyTable.end()) {
        moveFileToDest(srcPath, it->second);
        return;
    }

    // 未知のファイルを検索
    std::string foundPath = findInDirectory(searchTargetDir, filename);
    if (!foundPath.empty()) {
        std::cout << "[!] 候補を発見: " << foundPath <<  " に移動しますか？ [y/n]: ";
        char ans; std::cin >> ans;
        std::cin.ignore((std::numeric_limits<std::streamsize>::max)(), '\n');
        if (ans == 'y' || ans == 'Y') {
            if (moveFileToDest(srcPath, foundPath)) {
                // 履歴更新
                std::ofstream out(listFile, std::ios::app);
                out << foundPath << "\n";
                historyTable[filename] = foundPath;
            }
        }
    }
    else {
        std::cout << "[?] 未登録かつ候補なし: " << filename << "\n";
    }
}

void enumFiles(const std::string& dir, std::unordered_map<std::string, std::string>& historyTable) {
    WIN32_FIND_DATAA data;
    HANDLE h = FindFirstFileA((dir + "\\*").c_str(), &data);

    if (h == INVALID_HANDLE_VALUE) return;

    do {
        std::string name = data.cFileName;
        if (name == "." || name == "..") continue;

        std::string full = dir + "\\" + name;

        if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            // 再帰
            enumFiles(full, historyTable);
        }
        else {
            // ファイル処理
            searchMove(name, full, historyTable);
        }

    } while (FindNextFileA(h, &data));

    FindClose(h);
}




// --- メイン処理 ---
/*
    カレントディレクトリのsourceフォルダ 配下のファイルを再帰検索し、
    list.txt の配置履歴を基に targetDir 配下へ移動するツール。

    未登録ファイルは targetDir 内から同名ファイルを検索し、
    ユーザー確認後に移動先を履歴へ登録する。

    移動先に同名ファイルが存在する場合は .bak として退避する。
    比較はせずに、すべて上書き移動
*/
int main() {
    const std::string iniFile = ".\\config.ini";
    
    // INI設定読み込み
    sourceDir = ReadIniString(iniFile, "Settings", "SourceDir");
    listFile = ReadIniString(iniFile, "Settings", "ListFile");
    searchTargetDir = ReadIniString(iniFile, "Settings", "SearchTargetDir");
    backupMode = ReadIniInt(iniFile, "Settings", "BackupMode");
    useDryRun = ReadIniInt(iniFile, "Settings", "DryRun", 0);

    if (useDryRun) {
        std::cout << "【DryRunモードON】実際には実行せずに結果だけ表示します" << std::endl;
    }

    if (!PathUtils::exists(listFile)) {
        std::cerr << "エラー: リストファイルが見つかりません: " << listFile << "\n";
        return 1;
    }

    // 宛先一覧ファイル読み込み
    std::unordered_map<std::string, std::string> historyTable;
    std::ifstream in(listFile);
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty()) historyTable[PathUtils::getFileName(line)] = line;
    }
    in.close();

    // メイン処理
    enumFiles(sourceDir, historyTable);

    std::cout << "終了: Press Enter...";
    std::cin.get();
    return 0;
}