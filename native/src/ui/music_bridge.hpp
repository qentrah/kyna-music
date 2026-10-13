// Qt presentation, audio and persistence boundary. Kyna owns application behavior.
#pragma once
#include <kyna/native/adapter.hpp>
#include <QObject>
#include <QVariantMap>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QAudioBufferOutput>
#include <QTemporaryDir>
#include <QAudioDecoder>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <memory>
#include <unordered_map>

class MusicBridge final : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantMap state READ state NOTIFY stateChanged)
 Q_PROPERTY(bool playing READ playing NOTIFY playbackChanged)
 Q_PROPERTY(qint64 position READ position NOTIFY playbackChanged)
 Q_PROPERTY(qint64 duration READ duration NOTIFY playbackChanged)
 Q_PROPERTY(double volume READ volume NOTIFY playbackChanged)
public:
 explicit MusicBridge(kyna_native_host_v2 host);
 ~MusicBridge() override;
 QVariantMap state() const { return state_; }
 bool playing() const { return player_.playbackState()==QMediaPlayer::PlayingState; }
 qint64 position() const { return player_.position(); }
 qint64 duration() const { return player_.duration(); }
 double volume() const { return output_.volume(); }
 Q_INVOKABLE void send(const QString &action,const QString &payload=QString());
 void subscribe(uint64_t callback);
 void after(int milliseconds,uint64_t callback);
 void render(const std::string &json);
 void play(const QString &source);
 void toggle();
 void seek(qint64 position);
 void setVolume(double volume);
 QString status() const;
 QString load() const;
 void save(const QString &json) const;
 QString importFiles(const QString &json) const;
 QString libraryPath() const;
 QString failure, failureCode;
 signals:
 void stateChanged();
 void playbackChanged();
private:
 void invoke(uint64_t callback,const kyna::adapter::Value *values,size_t count);
 kyna_native_host_v2 host_{};
 uint64_t callback_{};
 std::unordered_map<uint64_t,uint64_t> timers_;
 uint64_t nextTimer_{1};
 QVariantMap state_;
 QTemporaryDir mediaCache_;
 QAudioOutput output_;
 QMediaPlayer player_;
 QAudioBufferOutput buffers_;
 std::unique_ptr<QAudioDecoder> verifier_;
 qint64 decodedFrames_{};
 QString mediaError_;
};
struct MusicSession {
 kyna_native_host_v2 host{};
 std::unique_ptr<QGuiApplication> application;
 std::unique_ptr<MusicBridge> bridge;
 std::unique_ptr<QQmlApplicationEngine> engine;
 bool running{};
 void initialize();
 ~MusicSession();
};
