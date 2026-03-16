#include <iostream>
#include <fstream>
#include <string>
#include <windows.h>
#include <shellapi.h>

bool FileExists(const std::string& path)
{
    DWORD attr = GetFileAttributesA(path.c_str());
    return (attr != INVALID_FILE_ATTRIBUTES &&
        !(attr & FILE_ATTRIBUTE_DIRECTORY));
}

int main(int argc, char* argv[])
{
    if (argc != 4)
    {
        std::cout << "usage: watchlog.exe <logfile> <keyphrase> <batfile>\n";
        return 1;
    }

    std::string logfile = argv[1];
    std::string key = argv[2];
    std::string bat = argv[3];

    // ログファイル確認
    if (!FileExists(logfile))
    {
        std::cout << "log file not found\n";
        return 1;
    }

    // batファイル確認
    if (!FileExists(bat))
    {
        std::cout << "bat file not found\n";
        return 1;
    }

    std::ifstream file(logfile);
    if (!file)
    {
        std::cout << "log open error\n";
        return 1;
    }

    // 末尾から監視
    file.seekg(0, std::ios::end);

    std::string line;

    while (true)
    {
        while (std::getline(file, line))
        {
            //std::cout << line << std::endl;

            if (line.find(key) != std::string::npos)
            {
                std::cout << "key detected\n";

                ShellExecuteA(
                    NULL,
                    "open",
                    bat.c_str(),
                    NULL,
                    NULL,
                    SW_SHOWNORMAL);

                return 0;
            }
        }

        file.clear();
        Sleep(1000);
    }
}