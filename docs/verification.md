# Verification

The Kyna smoke test checks six original tracks; case-insensitive search; likes; playlist create/add/remove; play-all queue; actual 40-second audio duration and advancing position; decoded PCM; pause/seek; next/previous; bounded volume and seek; callbacks after garbage collection; atomic persistence and a second VM process reload. Each test run uses a temporary application-data directory.

macOS native playback passed locally with 882,000 decoded frames per original track. The UI was launched as a real app and its playback controls were inspected through the accessibility tree. Platform CI must pass before its target is claimed verified.

Rams quick_review (`via: rules`) was attempted after UI changes. It returned exhausted one-time workspace credits, with no review findings. This is not a Rams approval.

Portable packaging recursively relocates dependency paths, records binary hashes, signs macOS bundles ad hoc and verifies their signature. Production signing/notarization and storefront publication are not part of this preview.

The complete local macOS bundle passed its audio smoke with Qt/QML environment paths pointed at nonexistent SDK locations. Apple `codesign --verify --deep --strict` passed. Packaged home, library/queue and search screenshots are saved in `docs/screenshots`.

The 25.5-second video in `docs/videos/kyna-music-macos.mp4` records actual app frames: playback, navigation, play-all queue and live search. It has no audio track. The compact screenshot verifies the 980-pixel layout with the right panel hidden and the transport retained.
