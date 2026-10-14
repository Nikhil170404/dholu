# Dholu

Zaroori notifications, sabse upar. *Only what matters, at the top.*

A free, private Android app (Flutter) that reads your notifications **on the phone**, hides the noise, and shows a
short list of what matters, with one-tap actions that open the right app. A small drummer, Dholu, announces urgent things.

## What it does

| Area | What you get |
|---|---|
| Triage | Notification listener (Kotlin), OTP/bank/password redaction first, rules scoring in English, Hindi and Hinglish, grouping ("Mummy ke 5 messages") |
| Summary | Morning summary notification (WorkManager, inexact), lock-screen privacy (counts only unless you opt in), in-app summary sheet |
| Act | Reply (AI or quick-reply draft, copied to clipboard), Pay / Track (opens the source app through the original notification's contentIntent). Dholu never sends, pays or deletes |
| Urgent | In-app shutter alert + drum roll in the foreground, an `urgent` notification in the background, drum alert with 3 choices, "Sahi chuna!" |
| On-device AI | Pick **Rules only**, a **small** (~0.8 GB) or **big** (~2 GB) model; the app reads your phone's RAM / storage / CPU and recommends one. Resumable, Wi-Fi-only downloads |
| Assistant | Chat, email drafting from your own message context (opens your email app, never sends), optional web search |
| Settings | Language (Hinglish/English), summary time, drum sound, lock-screen detail, models, web search, BYOK cloud model, "What Dholu knows" (view/delete data), permissions |

## Privacy model

- Everything is processed on the phone. **Notification text is never sent anywhere.**
- `INTERNET` is used only for things you switch on: model download, web search, and an optional cloud model with your own key.
  All are off by default. Web search sends only what you type in chat. A cloud model never classifies notifications and needs
  your explicit OK before it sees any stored message.
- OTPs, passwords and bank transaction text are never stored (a placeholder like "OTP received" is kept). Text is stored only for
  apps you marked important; other apps are just counted. Everything is deleted after 7 days. Backups are disabled.
- Keys live in the Android Keystore (`flutter_secure_storage`), never in preferences.

## Run

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after editing lib/data/database.dart
flutter run                                                # Android 7+ (API 24), arm64 for the AI models
flutter test                                               # 122 tests
```

Release: `flutter build apk --release --split-per-abi` or `flutter build appbundle --release`.
The first Android build downloads llama.cpp native libraries (llamadart build hook), so it needs internet.

## Layout

```
lib/core/       pure Dart: types, sensitive filter, rules classifier, dates, digest
lib/data/       Drift tables + Repository (privacy rules enforced here)
lib/native/     platform channel bridge, queue + important-apps files shared with Kotlin
lib/notif/      ingest pipeline, notification service (channels, lock-screen content)
lib/work/       WorkManager scheduler + background entry point
lib/ai/         model catalogue, recommender, downloader, llama.cpp + cloud backends, refiner
lib/assistant/  chat, email/reply drafting, web search providers
lib/ui/         screens   lib/mascot, lib/shutter: Dholu + the shutter alert
android/app/src/main/kotlin/com/dholu/app/   listener service, bridge, offline queue, sensitive guard
```

See `STACK.md` (choices), `docs/VERIFICATION.md` (what was and was not verified) and `docs/DEVICE_TEST.md` (manual checklist).
