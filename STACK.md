# Dholu stack (M1)

Chosen from PROJECT_BRIEF.md section 10 (Dholu_FLUTTER_RESEARCH.md was not in the repo).

| Concern | Choice | Notes |
|---|---|---|
| UI | Flutter 3.47 / Dart 3.13, Material 3 | Android only (`--platforms=android`), app id `com.dholu.app` |
| State | flutter_riverpod 3 | `Notifier` for the important-apps set |
| Routing | go_router | `/gallery` is a dev index of every M1 screen |
| Mascot | `CustomPainter` + `AnimationController` | No Rive/Lottie yet; geometry from brief section 7. Revisit if richer poses are needed |
| Font | Plus Jakarta Sans 500/600/700, bundled | Offline, so no internet permission is needed |

Not yet added (later milestones): Kotlin `NotificationListenerService` plugin (M2), Drift + encrypted store (M2),
`flutter_local_notifications` (M3), `workmanager` (M3).
