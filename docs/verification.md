# Verification

The Kyna smoke test checks six original tracks; case-insensitive search; likes; playlist create/add/remove; play-all queue; actual 40-second audio duration and advancing position; decoded PCM; pause/seek; next/previous; bounded volume and seek; callbacks after garbage collection; atomic persistence and a second VM process reload. Each test run uses a temporary application-data directory.

macOS native playback passed locally with 882,000 decoded frames per original track. The UI was launched as a real app and its playback controls were inspected through the accessibility tree. Platform CI must pass before its target is claimed verified.

Rams quick_review (`via: rules`) was attempted after UI changes. It returned exhausted one-time workspace credits, with no review findings. This is not a Rams approval.

Portable packaging recursively relocates dependency paths, records binary hashes, signs macOS bundles ad hoc and verifies their signature. Production signing/notarization and storefront publication are not part of this preview.

The complete local macOS bundle passed its audio smoke with Qt/QML environment paths pointed at nonexistent SDK locations. Apple `codesign --verify --deep --strict` passed. Packaged home, library/queue and search screenshots are saved in `docs/screenshots`.

The 25.5-second video in `docs/videos/kyna-music-macos.mp4` records actual app frames: playback, navigation, play-all queue and live search. It has no audio track. The compact screenshot verifies the 980-pixel layout with the right panel hidden and the transport retained.

## Verified desktop matrix

The final application code at `72a79fae0b5fcb4c1a3dd19aad874c9fcdbd39b7` passed the complete [desktop workflow](https://github.com/qentrah/kyna-music/actions/runs/38350021366) on 13 October 2026:

| Target | Evidence |
| --- | --- |
| Windows x86_64 | [Playback, persistence, native launcher and SDK-free package](https://github.com/qentrah/kyna-music/actions/runs/38350021366/job/115144612481) |
| Linux x86_64 / Ubuntu 24.04 | [Xvfb/PulseAudio application and portable package](https://github.com/qentrah/kyna-music/actions/runs/38350021366/job/115144612343) |
| macOS ARM64 / macOS 14 | [Application, signature and portable package](https://github.com/qentrah/kyna-music/actions/runs/38350021366/job/115144612507) |

These jobs build against Qt 6.8.3 and the pinned Kyna ABI 2 revision. The separate local macOS 6.11.2-Qt build also passed archive extraction into a relocated path containing spaces. Other CPU/OS combinations, production signatures and notarization are not established by these results.

The macOS archive downloaded from that CI run was also extracted and run locally: playback decoded 882,000 frames, the second-process persistence test passed, the native launcher passed, and strict code-signature verification passed.

## Preview source inventory

The draft preview combines the three verified CI archives with their audit reports and SHA-256 checksums. Corresponding Qt 6.8.3 source archives, FFmpeg 7.1 source and its detached signature, the vendor public key, and the Qt 6.8.3 provisioning/build recipes accompany it. The FFmpeg signature was verified in an isolated temporary keyring against the [officially published key](https://ffmpeg.org/download.html), fingerprint `FCF986EA15E6E293A5644F10B4322F04D67658D8`. `SOURCE-INVENTORY.json` records the hashes and upstream locations. Production signing and final third-party license clearance remain separate publication gates.
