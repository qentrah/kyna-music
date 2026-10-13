// Owns QML presentation and rooted, queued callbacks on the VM/UI thread.
#include "music_bridge.hpp"
#include <gui_runtime_paths.hpp>
#include <gui_module_lifetime.hpp>
#include <QQmlContext>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>
#include <QThread>
#include <QQuickStyle>
using namespace kyna::adapter;
MusicBridge::~MusicBridge(){
 player_.stop();
 if(callback_)host_.release_callback(host_.context,callback_);
 for(auto [_,callback]:timers_)host_.release_callback(host_.context,callback);
}
void MusicBridge::invoke(uint64_t callback,const Value *values,size_t count){
 auto result=host_.invoke_callback(host_.context,callback,values,count);
 if(result.error_code||result.error_message){failureCode=result.error_code?result.error_code:"KMUSIC1004";failure=result.error_message?result.error_message:"Music callback failed";QGuiApplication::quit();}
 if(result.release)result.release(result.context);
}
void MusicBridge::subscribe(uint64_t callback){
 if(!host_.retain_callback(host_.context,callback))throw Failure("KMUSIC1004","Cannot retain music event handler");
 if(callback_)host_.release_callback(host_.context,callback_);
 callback_=callback;
}
void MusicBridge::send(const QString &action,const QString &payload){
 QTimer::singleShot(0,this,[this,action,payload]{
  if(!callback_)return;
  Buffers buffers;Value args[]{buffers.string(action.toStdString()),buffers.string(payload.toStdString())};
  invoke(callback_,args,2);
 });
}
void MusicBridge::after(int milliseconds,uint64_t callback){
 if(!host_.retain_callback(host_.context,callback))throw Failure("KMUSIC1004","Cannot retain timer callback");
 auto id=nextTimer_++;timers_.emplace(id,callback);
 QTimer::singleShot(milliseconds,this,[this,id]{
  auto it=timers_.find(id);if(it==timers_.end())return;
  auto callback=it->second;invoke(callback,nullptr,0);
  host_.release_callback(host_.context,callback);timers_.erase(id);
 });
}
void MusicBridge::render(const std::string &json){
 auto document=QJsonDocument::fromJson(QByteArray::fromStdString(json));
 if(!document.isObject())throw Failure("KMUSIC1001","Music view must be a JSON object");
 state_=document.object().toVariantMap();emit stateChanged();
}
void MusicSession::initialize(){
 if(engine)return;
 auto existing=QCoreApplication::instance();
 if(existing&&(!qobject_cast<QGuiApplication*>(existing)||existing->thread()!=QThread::currentThread()))throw Failure("KMUSIC1004","Music requires the Qt GUI thread");
 kyna::gui::configurePackagedRuntime();kyna::gui::retainGuiModule();
 if(!existing){static int argc=1;static char name[]="Kyna Music";static char *argv[]{name,nullptr};application=std::make_unique<QGuiApplication>(argc,argv);}
 QCoreApplication::setOrganizationName("Kyna");QCoreApplication::setApplicationName("Kyna Music");
 QQuickStyle::setStyle("Basic");
 bridge=std::make_unique<MusicBridge>(host);
 auto initialized=std::make_unique<QQmlApplicationEngine>();
 kyna::gui::configurePackagedRuntime(initialized.get());
 initialized->rootContext()->setContextProperty("music",bridge.get());
 initialized->load(QUrl("qrc:/music/ui/Main.qml"));
 if(initialized->rootObjects().isEmpty())throw Failure("KMUSIC1002","Could not load the music interface; inspect QML diagnostics");
 engine=std::move(initialized);
}
MusicSession::~MusicSession(){engine.reset();bridge.reset();}
