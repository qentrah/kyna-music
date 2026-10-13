// Owns validated local music import and atomic, per-user library persistence.
#include "../ui/music_bridge.hpp"
#include <QStandardPaths>
#include <QSaveFile>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QCryptographicHash>
using namespace kyna::adapter;
namespace {
QJsonObject parseObject(const QByteArray &bytes){
 if(bytes.size()>8*1024*1024)throw Failure("KMUSIC1001","Music library exceeds the 8 MiB limit");
 QJsonParseError error{};auto doc=QJsonDocument::fromJson(bytes,&error);
 if(error.error!=QJsonParseError::NoError||!doc.isObject())throw Failure("KMUSIC1001","Music library is not valid JSON");
 auto obj=doc.object();
 if(!obj.value("volume").isDouble()||obj.value("volume").toDouble()<0||obj.value("volume").toDouble()>1)throw Failure("KMUSIC1001","Saved volume must be between zero and one");
 if(obj.value("version").toInt()!=1||!obj.value("tracks").isArray()||!obj.value("playlists").isArray())throw Failure("KMUSIC1001","Unsupported music library format");
 if(obj.value("tracks").toArray().size()>10000||obj.value("playlists").toArray().size()>1000)throw Failure("KMUSIC1001","Music library has too many entries");
 for(auto value:obj.value("tracks").toArray()){
  auto track=value.toObject();
  for(auto field:{"id","title","artist","album","path","art"})if(!track.value(field).isString())throw Failure("KMUSIC1001","Music library contains an invalid track");
  if(!track.value("liked").isBool())throw Failure("KMUSIC1001","Music library contains an invalid favorite");
 }
 for(auto value:obj.value("playlists").toArray()){
  auto p=value.toObject();if(!p.value("id").isString()||!p.value("name").isString()||!p.value("tracks").isArray())throw Failure("KMUSIC1001","Music library contains an invalid playlist");
  for(auto id:p.value("tracks").toArray())if(!id.isString())throw Failure("KMUSIC1001","Playlist track IDs must be text");
 }
 return obj;
}
}
QString MusicBridge::libraryPath() const{
 auto directory=qEnvironmentVariable("KYNA_MUSIC_DATA_DIR");
 if(directory.isEmpty())directory=QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
 return QDir(directory).filePath("library.json");
}
QString MusicBridge::load() const{
 QFile file(libraryPath());
 if(!file.exists()){
  QFile catalog(":/music/demo/catalog.json");if(!catalog.open(QIODevice::ReadOnly))throw Failure("KMUSIC1002","Demo catalog is missing");
  return QString::fromUtf8(QJsonDocument(parseObject(catalog.readAll())).toJson(QJsonDocument::Compact));
 }
 if(!file.open(QIODevice::ReadOnly))throw Failure("KMUSIC1002","Cannot read the music library");
 return QString::fromUtf8(QJsonDocument(parseObject(file.read(8*1024*1024+1))).toJson(QJsonDocument::Compact));
}
void MusicBridge::save(const QString &json) const{
 auto bytes=QJsonDocument(parseObject(json.toUtf8())).toJson(QJsonDocument::Compact);
 if(!QDir().mkpath(QFileInfo(libraryPath()).absolutePath()))throw Failure("KMUSIC1002","Cannot create music settings directory");
 QSaveFile file(libraryPath());if(!file.open(QIODevice::WriteOnly)||file.write(bytes)!=bytes.size()||!file.commit())throw Failure("KMUSIC1002","Cannot save the music library");
}
QString MusicBridge::importFiles(const QString &json) const{
 auto document=QJsonDocument::fromJson(json.toUtf8());
 if(!document.isArray()||document.array().size()>1000)throw Failure("KMUSIC1001","Import up to 1,000 local audio files at a time");
 QJsonArray tracks;
 for(auto value:document.array()){
  if(!value.isString())throw Failure("KMUSIC1001","Audio paths must be text");
  auto url=QUrl(value.toString());auto path=url.isLocalFile()?url.toLocalFile():value.toString();
  QFileInfo file(path);auto extension=file.suffix().toLower();
  if(!file.isFile()||!QStringList{"mp3","wav","flac","m4a","aac","ogg","opus","aiff","aif"}.contains(extension))throw Failure("KMUSIC1003","Import MP3, WAV, FLAC, M4A, AAC, Ogg, Opus or AIFF audio files");
  auto canonical=file.canonicalFilePath();auto hash=QCryptographicHash::hash(canonical.toUtf8(),QCryptographicHash::Sha256).toHex();
  auto title=file.completeBaseName(),artist=QString("Local artist");auto split=title.indexOf(" - ");if(split>0){artist=title.left(split);title=title.mid(split+3);}
  tracks.append(QJsonObject{{"id",QString::fromLatin1(hash)},{"path",QUrl::fromLocalFile(canonical).toString()},{"title",title},{"artist",artist},{"album","Your local library"},{"art","qrc:/music/ui/art/06.svg"},{"liked",false},{"duration","Local file"}});
 }
 return QString::fromUtf8(QJsonDocument(tracks).toJson(QJsonDocument::Compact));
}
