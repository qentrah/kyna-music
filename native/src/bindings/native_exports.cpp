// Typed ABI 2 exports for the Kyna Music application's Qt adapter.
#include "../ui/music_bridge.hpp"
#include <QThread>
#include <QRandomGenerator>
#include <QIcon>
#include <QImageReader>
using namespace kyna::adapter;
namespace {
MusicBridge &bridge(void *p){auto s=static_cast<MusicSession*>(p);s->initialize();if(QCoreApplication::instance()->thread()!=QThread::currentThread())throw Failure("KMUSIC1004","Music requires the UI thread");return *s->bridge;}
constexpr Type pair[]{text,text};
constexpr Type eventCallback{KYNA_V2_CALLBACK,0,nullptr,nullptr,pair,2,&nothing};
constexpr Type timerCallback{KYNA_V2_CALLBACK,0,nullptr,nullptr,nullptr,0,&nothing};
constexpr Type eventArgs[]{eventCallback},textArgs[]{text},numberArgs[]{number},intArgs[]{integer},afterArgs[]{integer,timerCallback};
kyna_native_result_v2 open(void*p,const Value*,size_t) noexcept{return guarded([&](Buffers&){bridge(p);return Value{};});}
kyna_native_result_v2 icon(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p);const auto path=QString::fromStdString(string(a[0]));QImageReader reader(path);if(reader.read().isNull())throw Failure("KMUSIC1001","App icon must be a readable local image or Qt resource");QGuiApplication::setWindowIcon(QIcon(path));return Value{};});}
kyna_native_result_v2 on(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).subscribe(a[0].handle);return Value{};});}
kyna_native_result_v2 render(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).render(string(a[0]));return Value{};});}
kyna_native_result_v2 load(void*p,const Value*,size_t) noexcept{return guarded([&](Buffers&b){return b.string(bridge(p).load().toStdString());});}
kyna_native_result_v2 save(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).save(QString::fromStdString(string(a[0])));return Value{};});}
kyna_native_result_v2 importTracks(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&b){return b.string(bridge(p).importFiles(QString::fromStdString(string(a[0]))).toStdString());});}
kyna_native_result_v2 play(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).play(QString::fromStdString(string(a[0])));return Value{};});}
kyna_native_result_v2 toggle(void*p,const Value*,size_t) noexcept{return guarded([&](Buffers&){bridge(p).toggle();return Value{};});}
kyna_native_result_v2 seek(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).seek(a[0].integer);return Value{};});}
kyna_native_result_v2 volume(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){bridge(p).setVolume(finite(a[0]));return Value{};});}
kyna_native_result_v2 status(void*p,const Value*,size_t) noexcept{return guarded([&](Buffers&b){return b.string(bridge(p).status().toStdString());});}
kyna_native_result_v2 after(void*p,const Value*a,size_t) noexcept{return guarded([&](Buffers&){if(a[0].integer<0||a[0].integer>2147483647)throw Failure("KMUSIC1001","Timer must be a nonnegative 32-bit duration");bridge(p).after(int(a[0].integer),a[1].handle);return Value{};});}
kyna_native_result_v2 run(void*p,const Value*,size_t) noexcept{return guarded([&](Buffers&){auto s=static_cast<MusicSession*>(p);auto &b=bridge(p);if(s->running)throw Failure("KMUSIC1004","Music loop is already running");s->running=true;QGuiApplication::exec();s->running=false;if(!b.failure.isEmpty())throw Failure(b.failureCode.toStdString(),b.failure.toStdString());return Value{};});}
kyna_native_result_v2 quit(void*,const Value*,size_t) noexcept{return guarded([&](Buffers&){QGuiApplication::quit();return Value{};});}
kyna_native_result_v2 randomIndex(void*,const Value*a,size_t) noexcept{return guarded([&](Buffers&){if(a[0].integer<=0||a[0].integer>2147483647)throw Failure("KMUSIC1001","Random upper bound must be a positive 32-bit integer");return whole(QRandomGenerator::global()->bounded(int(a[0].integer)));});}
const kyna_native_function_v2 functions[]{
 {"musicIcon",textArgs,1,nothing,icon},{"musicOpen",nullptr,0,nothing,open},{"musicOnEvent",eventArgs,1,nothing,on},{"musicRender",textArgs,1,nothing,render},
 {"musicLoad",nullptr,0,text,load},{"musicSave",textArgs,1,nothing,save},{"musicImport",textArgs,1,text,importTracks},
 {"musicPlay",textArgs,1,nothing,play},{"musicToggle",nullptr,0,nothing,toggle},{"musicSeek",intArgs,1,nothing,seek},
 {"musicVolume",numberArgs,1,nothing,volume},{"musicStatus",nullptr,0,text,status},{"musicAfter",afterArgs,2,nothing,after},
 {"musicRandom",intArgs,1,integer,randomIndex},{"musicRun",nullptr,0,nothing,run},{"musicQuit",nullptr,0,nothing,quit}};
const kyna_native_module_v2_descriptor descriptor{2,sizeof(descriptor),"music","1.0.0",functions,std::size(functions),create<MusicSession>,close<MusicSession>,nullptr,nullptr};
}
extern "C" KYNA_NATIVE_EXPORT const kyna_native_module_v2_descriptor *kyna_native_module_v2(){return &descriptor;}
