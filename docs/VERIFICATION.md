# What was verified, and what was not

Built in a Linux container with no Android SDK, no device, and no access to Hugging Face / dl.google.com.

## Verified (automated)
- `flutter analyze`: no issues. `flutter test`: **122 tests pass**.
- Domain: OTP/bank/password redaction (incl. a punctuation bug the tests caught), EN/HI/Hinglish scoring, due dates,
  grouping, digest, 7-day purge, privacy rules in the repository (text only for important apps, OTP never stored).
- Pipelines with fakes: ingest (live + offline queue), AI refinement, urgent routing (foreground vs background),
  lock-screen content (counts only by default), model download manager (size/storage/GGUF checks, Wi-Fi setting),
  recommender across 2/4/8/12 GB phones, web-search parsers, chat + email/reply drafting, cloud consent, BYOK streaming.
- UI flows (widget tests): home, summary, reply draft, drum alert, done, choose apps, tips, settings, models, assistant,
  email, privacy screen, shutter alert.
- Kotlin: type-checked with `kotlinc` against Android 14 framework classes and Flutter's embedding jar (all files;
  `MainActivity` only lacks androidx jars in the sandbox). Manifest and resource XML parse.

## NOT verified. Needs a real phone
1. **`flutter build apk` was never run** (no Android SDK). Gradle config follows each plugin's README; expect to fix small things.
2. **llama.cpp inference** (`LocalLlm`) type-checks against llamadart but never ran a model. Speed, RAM and Hindi/Hinglish
   quality on real phones are unknown. Model file names/URLs and the 2 GB size are unverified (Hugging Face blocked).
3. **NotificationListenerService** behaviour on real OEM builds (Xiaomi/Oppo/Vivo may kill it; use Settings > Remove battery limit).
4. **WorkManager** timing (inexact by design) and the background isolate (Drift DB + notifications) on a device.
5. Lock-screen behaviour, notification sound channel, drum sound volume, `startActivity` for email and `PendingIntent` redirects.
6. DuckDuckGo HTML parsing depends on their markup; Brave/SearXNG paths are tested with mocks only.
7. No accessibility pass with TalkBack, no 2 GB-phone performance test, no Play Store review.

## Deviations from the brief
- `INTERNET` permission exists (opt-in features only). The brief said none for the MVP; model download and web search need it.
- SQLite is not encrypted with SQLCipher (see STACK.md for the mitigations).
- Lock screen "public version" is done by making the notification itself count-only (`flutter_local_notifications` has no public-version API).
- Screens 3 (lock summary) and 8 (heads-up) are Android notifications, not Flutter screens.
- No custom-model URL yet; no Devanagari font bundled (Hindi script falls back to the system font).
