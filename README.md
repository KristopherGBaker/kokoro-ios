# KokoroSwift — Japanese-enabled fork

A maintained fork of [mlalma/kokoro-ios](https://github.com/mlalma/kokoro-ios)
(KokoroSwift), the Swift/MLX port of the [Kokoro](https://github.com/hexgrad/kokoro)
neural TTS model. This fork adds **Japanese synthesis** (with pitch-accent-aware
phonemes) and **mixed Japanese/English code-switching** alongside the original
English support, and tracks a pinned MLX toolchain that runs cleanly on current
Apple Silicon.

It powers [Aoede](https://github.com/KristopherGBaker/Aoede), a local-first reader
for macOS and iOS/iPadOS that reads English and Japanese with furigana.

> **Relationship to upstream.** All of the original engine — the PyTorch→MLX port,
> the audio graph, per-token timestamps — is mlalma's (and the
> [MLX-Audio](https://github.com/Blaizzy/mlx-audio) project it ports). This fork
> exists because upstream is no longer actively taking changes, in particular
> non-English support. We keep it on the `feat/japanese-g2p` branch and develop in
> the open; PRs upstream would be welcome if that ever changes. Original work is
> retained under its MIT license (see [LICENSE](LICENSE)).

## What this fork adds

- **Japanese (`.ja`) synthesis** routed through our
  [MisakiSwift fork](https://github.com/KristopherGBaker/MisakiSwift)'s Japanese
  G2P — true readings + pitch-accent metadata via an OpenJTalk frontend, with a
  pure-Apple fallback when no dictionary is installed.
- **Mixed JA/EN code-switching.** `setLanguage(_:)` keeps each language's G2P
  engine **built once and cached**, so a caller can alternate languages within a
  single utterance without rebuilding the (expensive) OpenJTalk frontend each time.
- **MLX 0.31.4 pin.** `mlx-swift` is pinned `exact: "0.31.4"` — 0.30.x garbles
  synthesis onsets on some devices (e.g. M-series with newer GPUs).
- Per-token timestamps (from upstream) used to drive word-level karaoke highlight
  timing.

## Requirements

- iOS 18.0+ / macOS 15.0+ (other Apple platforms may work)
- Apple Silicon — MLX requires a Metal GPU. **MLX does not run on the iOS
  Simulator**, so Japanese/Kokoro synthesis must be exercised on a real device.

## Installation

Swift Package Manager — point at this fork's branch:

```swift
dependencies: [
    .package(url: "https://github.com/KristopherGBaker/kokoro-ios", branch: "feat/japanese-g2p")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "KokoroSwift", package: "kokoro-ios")
    ]
)
```

The Japanese G2P dependency ([MisakiSwift fork](https://github.com/KristopherGBaker/MisakiSwift))
must be pinned to the **same** `feat/japanese-g2p` branch.

## Usage

You supply the Kokoro model weights and a voice style (`MLXArray`); see
[KokoroTestApp](https://github.com/mlalma/KokoroTestApp) for how to obtain them.

### English

```swift
import KokoroSwift

let tts = KokoroTTS(modelPath: modelURL, g2p: .misaki)
let (audio, tokens) = try tts.generateAudio(voice: voiceEmbedding, language: .enUS, text: "Hello, world.")
```

### Japanese

```swift
import KokoroSwift
import MisakiSwift

// Point the Japanese G2P at an Open JTalk UTF-8 dictionary for true readings +
// pitch accent. Without this it falls back to a pure-Apple reading engine.
JapaneseG2PConfiguration.dictionaryDirectory = openJTalkDictionaryURL

let (audio, tokens) = try tts.generateAudio(voice: japaneseVoice, language: .ja, text: "こんにちは、世界。")
```

`generateAudio` returns the audio samples plus per-token `MToken`s carrying
`start_ts` / `end_ts` for highlight syncing.

### Mixed Japanese + English

Kokoro synthesizes one voice per call. To read text that mixes scripts, split it
into runs and call `generateAudio` per run with the matching `language` (and,
optionally, a per-language voice), then concatenate the audio. Because the G2P
engines are cached, alternating `.ja` / `.enUS` across runs no longer reloads the
OpenJTalk dictionary each time. (Aoede implements this split + stitch on top of
this library.)

## G2P (grapheme-to-phoneme) options

- `.misaki` — [MisakiSwift](https://github.com/KristopherGBaker/MisakiSwift)
  (default): English + Japanese, no eSpeak dependency.
- `.espeak` — eSpeak NG (optional/commented out upstream).

## Model files

Kokoro model weights and voice styles are not bundled (size). See
[KokoroTestApp](https://github.com/mlalma/KokoroTestApp) for packaging them.

## Dependencies

- [MLX Swift](https://github.com/ml-explore/mlx-swift) — pinned `exact: "0.31.4"`
- [MisakiSwift (fork)](https://github.com/KristopherGBaker/MisakiSwift) — English + Japanese G2P
- [MLXUtilsLibrary](https://github.com/mlalma/MLXUtilsLibrary) — `MToken` and shared utilities

## Credits

- **Kokoro model** — [hexgrad](https://github.com/hexgrad/kokoro)
- **MLX Python port** — [MLX-Audio](https://github.com/Blaizzy/mlx-audio)
- **Swift/MLX port (KokoroSwift)** — [Lassi Maksimainen (mlalma)](https://github.com/mlalma/kokoro-ios)
- **Japanese support + this fork** — [Kristopher Baker](https://github.com/KristopherGBaker)

## License

MIT — see [LICENSE](LICENSE). Original copyright © 2025 Lassi Maksimainen;
fork modifications © 2025–2026 Kristopher Baker, released under the same license.
