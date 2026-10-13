# Visual references and asset provenance

The visual pass inspected the [Spotify desktop redesign screenshot](https://images.macrumors.com/t/Z0THmgSRAkejIY4p_bHOjqfp2fA%3D/1600x0/article-new/2023/06/spotify-desktop-redesign.jpg): black gutters, separate dark panels, compact two-row shortcut grid, album cards, a right now-playing panel and bottom transport. Search also found Spotify Community references; their image URLs currently redirect to the replacement community's not-found page, so they were not used as verified visual evidence.

This implementation keeps its own Kyna Music identity and local-library behavior. Artwork, labels, window decorations and responsive breakpoints differ; pixel-perfect equivalence has not been established. Below 1200 pixels the now-playing panel collapses, and the album grid and transport adapt to the remaining width.

All bundled covers (`ui/art`), control icons (`ui/icons`) and generated WAVs (`tools/generate_demo.py`) are original CC0 assets. No reference screenshot is bundled as an application asset. Technical references: [QMediaPlayer](https://doc.qt.io/qt-6/qmediaplayer.html), [QAudioDecoder](https://doc.qt.io/qt-6/qaudiodecoder.html).
