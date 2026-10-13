// Starts the packaged Kyna entry point from a relocatable desktop executable.
#include <filesystem>
#include <string>
#include <vector>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
int WINAPI wWinMain(HINSTANCE,HINSTANCE,PWSTR arguments,int) {
 std::vector<wchar_t> buffer(32768);
 auto length=GetModuleFileNameW(nullptr,buffer.data(),DWORD(buffer.size()));
 if(!length||length==buffer.size())return 1;
 const auto root=std::filesystem::path(buffer.data()).parent_path();
 const auto runtime=root/L"bin";const auto program=runtime/L"ky.exe";
 const bool smoke=std::wstring(arguments)==L"--smoke";
 auto command=L"\""+program.wstring()+L"\" --native-library \""+(runtime/L"music_bridge.dll").wstring()+L"\" run "+(smoke?L"tests/launch.ky":L"main.ky");
 STARTUPINFOW startup{};startup.cb=sizeof(startup);PROCESS_INFORMATION process{};
 if(!CreateProcessW(program.c_str(),command.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,(root/L"app").c_str(),&startup,&process)){
  MessageBoxW(nullptr,L"Kyna Music could not start. Extract the complete application archive before opening it.",L"Kyna Music",MB_OK|MB_ICONERROR);return 1;
 }
 CloseHandle(process.hThread);WaitForSingleObject(process.hProcess,INFINITE);
 DWORD status=1;GetExitCodeProcess(process.hProcess,&status);CloseHandle(process.hProcess);return int(status);
}
#else
#include <unistd.h>
#include <iostream>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif
int main(int argc,char **argv) {
 std::filesystem::path executable;
#ifdef __APPLE__
 uint32_t size=0;_NSGetExecutablePath(nullptr,&size);std::vector<char> buffer(size);
 if(_NSGetExecutablePath(buffer.data(),&size))return 1;
 executable=std::filesystem::canonical(buffer.data());
 const auto root=executable.parent_path()/"../Resources";
 const auto runtime=root/"runtime";
#else
 std::vector<char> buffer(32768);auto length=readlink("/proc/self/exe",buffer.data(),buffer.size());
 if(length<=0||static_cast<size_t>(length)==buffer.size())return 1;
 executable=std::filesystem::path(std::string(buffer.data(),size_t(length)));
 const auto root=executable.parent_path();const auto runtime=root/"bin";
#endif
 const auto program=(runtime/"ky").string();const auto module=(runtime/"libmusic_bridge.so").string();
 std::error_code error;std::filesystem::current_path(root/"app",error);
 if(error){std::cerr<<"Cannot open packaged Kyna application: "<<error.message()<<"\n";return 1;}
 const bool smoke=argc==2&&std::string(argv[1])=="--smoke";
 const char *args[]{program.c_str(),"--native-library",module.c_str(),"run",smoke?"tests/launch.ky":"main.ky",nullptr};
 execv(program.c_str(),const_cast<char *const *>(args));perror("Cannot start Kyna Music");return 1;
}
#endif
