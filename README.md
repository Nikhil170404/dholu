# Dholu

Zaroori notifications, sabse upar. Only what matters, at the top. See `PROJECT_BRIEF.md` and `STACK.md`.

## Run

```
flutter pub get
flutter run          # Android device/emulator
flutter test         # widget tests + mascot golden
```

Open `/gallery` (or use the app flow: Loading -> Tips -> Home) to see every M1 screen.
Refresh the mascot golden with `flutter test --update-goldens test/golden_test.dart`.

## Release build (small APKs)

```
flutter build apk --release --split-per-abi   # one slim APK per CPU
flutter build appbundle --release             # for Play Store
```
R8 minify + resource shrinking are on for release; fonts are Latin-subset (about 21 KB each).
