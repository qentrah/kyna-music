// Owns actual media decoding, playback state and bounded transport controls.
#include "../ui/music_bridge.hpp"
#include <QFileInfo>
#include <QFile>
#include <QAudioBuffer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <cmath>
using namespace kyna::adapter;
MusicBridge::MusicBridge(kyna_native_host_v2 host):host_(host){
 if(qEnvironmentVariableIntValue("KYNA_MUSIC_VERIFY_AUDIO")==1){
  verifier_=std::make_unique<QAudioDecoder>();
  connect(verifier_.get(),&QAudioDecoder::bufferReady,this,[this]{decodedFrames_+=verifier_->read().frameCount();});
 }
 player_.setAudioOutput(&output_);player_.setAudioBufferOutput(&buffers_);output_.setVolume(0.65);
 connect(&player_,&QMediaPlayer::positionChanged,this,&MusicBridge::playbackChanged);
 connect(&player_,&QMediaPlayer::durationChanged,this,&MusicBridge::playbackChanged);
 connect(&player_,&QMediaPlayer::playbackStateChanged,this,&MusicBridge::playbackChanged);
 connect(&output_,&QAudioOutput::volumeChanged,this,&MusicBridge::playbackChanged);
 connect(&buffers_,&QAudioBufferOutput::audioBufferReceived,this,[this](const QAudioBuffer &buffer){if(!verifier_)decodedFrames_+=buffer.frameCount();});
 connect(&player_,&QMediaPlayer::mediaStatusChanged,this,[this](QMediaPlayer::MediaStatus status){if(status==QMediaPlayer::EndOfMedia)send("ended");});
 connect(&player_,&QMediaPlayer::errorOccurred,this,[this](QMediaPlayer::Error,const QString &message){mediaError_=message;send("error",message);});
}
void MusicBridge::play(const QString &source){
 auto url=QUrl(source);
 if(url.scheme()=="qrc"){
  if(!source.startsWith("qrc:/music/demo/")||!QFileInfo::exists(":"+url.path()))throw Failure("KMUSIC1003","Demo track is missing");
  // AVFoundation requires a real file URL; own the extracted file until playback ends.
  if(!mediaCache_.isValid())throw Failure("KMUSIC1002","Cannot create the audio cache");
  const auto file=mediaCache_.filePath(QFileInfo(url.path()).fileName());
  if(!QFileInfo::exists(file)&&!QFile::copy(":"+url.path(),file))throw Failure("KMUSIC1002","Cannot extract demo audio");
  url=QUrl::fromLocalFile(file);
 }else{
  if(url.isLocalFile())url=QUrl::fromLocalFile(QFileInfo(url.toLocalFile()).absoluteFilePath());
  else if(url.scheme().isEmpty())url=QUrl::fromLocalFile(QFileInfo(source).absoluteFilePath());
  else throw Failure("KMUSIC1003","Select a local audio file");
  if(!QFileInfo(url.toLocalFile()).isFile())throw Failure("KMUSIC1003","This audio file was moved or deleted. Import it again.");
 }
 if(verifier_)verifier_->stop();
 decodedFrames_=0;mediaError_.clear();player_.setSource(url);player_.play();
 if(verifier_){verifier_->setSource(url);verifier_->start();}
}
void MusicBridge::toggle(){if(playing())player_.pause();else if(!player_.source().isEmpty())player_.play();}
void MusicBridge::seek(qint64 value){if(value<0||value>player_.duration())throw Failure("KMUSIC1001","Seek position is outside this track");player_.setPosition(value);}
void MusicBridge::setVolume(double value){if(!std::isfinite(value)||value<0||value>1)throw Failure("KMUSIC1001","Volume must be between zero and one");output_.setVolume(float(value));}
QString MusicBridge::status() const{
 return QString::fromUtf8(QJsonDocument(QJsonObject{{"playing",playing()},{"position",position()},{"duration",duration()},{"volume",volume()},{"decodedFrames",decodedFrames_},{"error",mediaError_}}).toJson(QJsonDocument::Compact));
}
