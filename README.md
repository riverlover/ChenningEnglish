# Chenning

Cross-platform English word-block app for kids (Flutter).

## Locked product choices

- Brand: **Chenning** (English only)
- TTS: **en-US**
- MVP: full **9 quest levels** + Grade 5 Beijing Publishing House word bank (170)

## Run on Android phone

1. Phone: enable Developer options → USB debugging, plug in USB.
2. Mac terminal:

```bash
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890
export no_proxy='localhost,127.0.0.1,::1' NO_PROXY='localhost,127.0.0.1,::1'
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="/opt/homebrew/bin:$ANDROID_HOME/platform-tools:$PATH"

cd /Users/lizhenhe/apps/ChenningEnglish
adb devices
flutter run
```

Or install the already-built debug APK:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Content

- `assets/vocab/grade5_beijing.json` — 170 words
- `assets/levels/grade5_levels.json` — 9 interactive levels
- `assets/audio/en-us/*.mp3` — pre-generated neural US English (Edge Aria)
- `assets/audio/manifest.json` — clip index + optional `remoteBaseUrl`

## Audio (pre-generated neural TTS)

Speak path: **bundled MP3 → optional CDN URL → system TTS fallback**.

Regenerate after vocab / level word changes:

```bash
/opt/homebrew/bin/python3.11 -m venv tool/.venv
tool/.venv/bin/pip install -r tool/requirements-audio.txt
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890
tool/.venv/bin/python tool/generate_audio.py --proxy http://127.0.0.1:7890
```

When a backend / CDN is ready, set `remoteBaseUrl` in `manifest.json` (or call
`TtsService.configureRemoteBaseUrl(...)` after fetching app config). The same
`en-us/{key}.mp3` paths can be served remotely and prefetched on demand.

## Features in this build

- Home · Quest Map (9 levels, unlock in order) · Word Bank · Today review (SRS)
- en-US neural audio on word cards / questions (system TTS fallback)
- Progress + wrong-book + Leitner spaced repetition (1 / 3 / 7 / 30 days)
