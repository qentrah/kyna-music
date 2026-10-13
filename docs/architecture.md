# Application architecture

The VM runs `main.ky`, which initializes Kyna state and subscribes one typed `fn(str, str): void` event handler. Qt clicks enqueue action/payload pairs on the UI thread; Kyna processes them and sends a new JSON view to QML. Qt does not own playlist or queue decisions.

`music_bridge` publishes a versioned C ABI descriptor shared by `ky check` and runtime registration. All calls cross guarded exception boundaries and validate native conversions. Event callbacks and timers are retained until replacement, delivery or session destruction. Timers use the bridge as their Qt context, so destruction cancels pending delivery. QML objects disappear before the bridge and the application.

Qt Multimedia decodes and plays real local audio. Embedded demonstration WAVs are extracted to a session-owned temporary directory for AVFoundation; files remain alive through player destruction. Verification mode enables a separate QAudioDecoder because the native macOS backend does not expose QAudioBufferOutput samples. Tests check both actual decoding and advancing playback position; decoder samples alone are not used as proof of playback.

Storage validates bounded JSON records and uses QSaveFile for atomic replacement. Import assigns each canonical local path a SHA-256 identifier, making repeated imports idempotent. Kyna treats native storage/media failures as visible notices.

Typed functions: `musicOpen`, `musicIcon(str)`, `musicOnEvent(fn(str,str):void)`, `musicRender(str)`, `musicLoad():str`, `musicSave(str)`, `musicImport(str):str`, `musicPlay(str)`, `musicToggle`, `musicSeek(int)`, `musicVolume(float)`, `musicStatus():str`, `musicAfter(int,fn():void)`, `musicRandom(int):int`, `musicRun`, `musicQuit`.

Error codes: KMUSIC1001 invalid input/schema, KMUSIC1002 storage or UI initialization, KMUSIC1003 media/file, KMUSIC1004 callback/thread/lifecycle. Runtime errors retain compiler source locations through the Kyna native interface.
