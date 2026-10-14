# Manual device test checklist

Use a real arm64 Android 8+ phone (ideally also a 3-4 GB phone).

1. `flutter run --release`. Loading -> Tips -> "Notification access do" -> enable Dholu in system settings -> back in app -> pick apps -> Home.
2. Send yourself a WhatsApp message with "urgent report 10 baje tak bhejna" from a second phone: app open -> shutter alert + drum roll;
   app backgrounded -> urgent notification (generic text unless lock-screen detail is on).
3. Phone on silent / Do Not Disturb: no drum sound.
4. Send an OTP SMS: Settings > What Dholu knows shows only "OTP received", never the digits.
5. Kill the app, send messages, reopen: they appear (offline queue). Messages from non-important apps show no text.
6. Settings > AI model: check the recommendation matches the phone; download the small model on Wi-Fi, background the app, confirm it finishes;
   try pause / resume / delete; turn Wi-Fi-only off and on mobile data.
7. Reply -> draft appears (model load time on this phone?) -> "WhatsApp mein kholo" -> paste works, nothing is sent.
8. Talk tab: ask something; enable web search + provider and ask a current question; email: draft, open in email app.
9. Summary time 2 minutes ahead: notification arrives with the app closed (try on your OEM; check battery settings).
10. Reboot: next morning summary still arrives. Language toggle Hinglish/English. TalkBack on Home and Settings.
