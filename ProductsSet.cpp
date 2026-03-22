#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <windows.h>

const std::string sourceDir = "source";
const std::string listFile = "list.txt";
const std::string targetDir = "C:\\Users\\miyuj\\Desktop\\dest";

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

    bool exists(const std::string& path) {
        return GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES;
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
            CreateDirectoryA(current.c_str(), NULL);
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
    oss << filePath << ".bak" << std::put_time(&tm, "%Y%m%d%H%M");

    if (MoveFileA(filePath.c_str(), oss.str().c_str())) {
        std::cout << "[Backup] " << PathUtils::getFileName(filePath) << " を退避しました。\n";
    }
}

// フォルダ作成を伴う移動
bool moveFileToDest(const std::string& src, const std::string& dest) {
    if (PathUtils::exists(dest)) {
        createBackup(dest);
    }
    else {
        std::string destFolder = PathUtils::getParentPath(dest);
        if (!PathUtils::exists(destFolder)) {
            PathUtils::createDirectories(destFolder);
        }
    }

    if (MoveFileA(src.c_str(), dest.c_str())) {
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
    std::string foundPath = findInDirectory(targetDir, filename);
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

int main() {
    if (!PathUtils::exists(listFile)) {
        std::cerr << "エラー: リストファイルが見つかりません: " << listFile << "\n";
        return 1;
    }

    std::unordered_map<std::string, std::string> historyTable;
    std::ifstream in(listFile);
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty()) historyTable[PathUtils::getFileName(line)] = line;
    }
    in.close();

    enumFiles(sourceDir, historyTable);

    std::cout << "終了: Press Enter...";
    std::cin.get();
    return 0;
}