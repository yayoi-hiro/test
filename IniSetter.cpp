#include <windows.h>
#include <iostream>
#include <string>

void usage()
{
    std::cout << "usage:\n";
    std::cout << "ini get -f <file_fullpath> -s <section> -k <key>\n";
    std::cout << "ini set -f <file_fullpath> -s <section> -k <key> -v <value>\n";
}

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        usage();
        return 1;
    }

    std::string cmd = argv[1];
    std::string file, section, key, value;

    for (int i = 2; i < argc; i++)
    {
        std::string arg = argv[i];

        if (arg == "-f" && i + 1 < argc)
            file = argv[++i];
        else if (arg == "-s" && i + 1 < argc)
            section = argv[++i];
        else if (arg == "-k" && i + 1 < argc)
            key = argv[++i];
        else if (arg == "-v" && i + 1 < argc)
            value = argv[++i];
        else
        {
            std::cerr << "invalid argument: " << arg << "\n";
            usage();
            return 1;
        }
    }

    // 必須チェック
    if (file.empty() || section.empty() || key.empty())
    {
        std::cerr << "missing required argument\n";
        usage();
        return 1;
    }

    if (cmd == "get")
    {
        char buf[4096];

        DWORD len = GetPrivateProfileStringA(
            section.c_str(),
            key.c_str(),
            "",
            buf,
            sizeof(buf),
            file.c_str()
        );

        if (len == 0) {
            std::cout << "key not found" << std::endl;
            return 2;
        }

        std::cout << buf << std::endl;
    }
    else if (cmd == "set")
    {
        if (value.empty())
        {
            std::cerr << "-v required for set\n";
            return 1;
        }

        char buf[4096];

        DWORD len = GetPrivateProfileStringA(
            section.c_str(),
            key.c_str(),
            "",
            buf,
            sizeof(buf),
            file.c_str()
        );

        // key= で値が空文字のときはキーが存在しないとみなす
        if (len == 0) {
            std::cout << "key not found" << std::endl;
            return 2;
        }

        BOOL result = WritePrivateProfileStringA(
            section.c_str(),
            key.c_str(),
            value.c_str(),
            file.c_str());

        if (!result)
        {
            std::cerr << "write failed\n";
            return 3;
        }
    }
    else
    {
        std::cerr << "unknown command\n";
        usage();
        return 1;
    }

    return 0;
}