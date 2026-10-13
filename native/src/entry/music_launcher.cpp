// Launches the packaged Kyna program relative to this executable.
#include <mach-o/dyld.h>
#include <unistd.h>
#include <filesystem>
#include <iostream>
#include <vector>
int main() {
 uint32_t size=0;_NSGetExecutablePath(nullptr,&size);
 std::vector<char> buffer(size);
 if(_NSGetExecutablePath(buffer.data(),&size))return 1;
 auto bin=std::filesystem::canonical(buffer.data()).parent_path();
 auto program=(bin/"ky").string();auto module=(bin/"libmusic_bridge.so").string();
 std::error_code error;std::filesystem::current_path(bin/"../Resources/app",error);
 if(error){std::cerr<<"Cannot open packaged Kyna application: "<<error.message()<<"\n";return 1;}
 const char *args[]{program.c_str(),"--native-library",module.c_str(),"run","main.ky",nullptr};
 execv(program.c_str(),const_cast<char *const *>(args));
 perror("Cannot start Kyna Music");return 1;
}
