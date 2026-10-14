# Dholu stack

| Concern | Choice | Notes |
|---|---|---|
| UI | Flutter 3.47 / Dart 3.13, Material 3 | Android only, app id `com.dholu.app`, minSdk 24 |
| State | flutter_riverpod 3 | |
| Routing | go_router | debug-only `/gallery` index |
| Storage | Drift + SQLite (app-private) | Plain SQLite, not SQLCipher: only redacted text is stored, 7-day purge, backups disabled |
| Native | App-level Kotlin (`NotificationListenerService`, MethodChannel/EventChannel) | |
| Notifications | flutter_local_notifications 22 (needs core-library desugaring, set in Gradle) | |
| Background | workmanager (inexact one-off, re-armed daily) | no exact-alarm permission |
| On-device LLM | llamadart (llama.cpp, GGUF, CPU) | only the `llama_cpp` runtime is bundled (see `hooks` in pubspec) |
| Downloads | background_downloader (WorkManager, resumable, Wi-Fi-only option) | |
| Secrets | flutter_secure_storage (Android Keystore) | |
| Mascot | `CustomPainter` | geometry from the brief |
| Font | Plus Jakarta Sans 500/600/700, Latin-subset, bundled | |

## Model tiers

| Tier | Model | Size | Phone |
|---|---|---|---|
| small | Gemma 3 1B IT, Q4_K_M | ~0.81 GB | 3 GB+ RAM |
| big | Llama 3.2 3B Instruct, Q4_K_M | ~2.0 GB (estimate) | 6 GB+ RAM |
| max | Qwen3 4B, Q4_K_M | ~2.5 GB | 8 GB+ RAM |

The recommender needs a 64-bit ARM phone and checks RAM, free storage and Android's low-RAM flag. Files come from the
bartowski GGUF repos on Hugging Face; the app checks the real size with a HEAD request before downloading.
Check each model's licence (Gemma terms, Llama 3.2 community licence, Apache 2.0) before shipping.
