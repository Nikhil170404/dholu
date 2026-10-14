package com.dholu.app

import android.app.Notification
import android.app.PendingIntent
import android.content.ComponentName
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.util.Collections

/**
 * Owns the other apps' notifications. Dart never touches them directly: this
 * service extracts text, keeps each notification's contentIntent so a tap in Dholu can
 * open the source app at the right place, and forwards events to Dart (live) or to
 * the on-disk queue (when the Flutter engine is not attached).
 *
 * Dholu never cancels or alters the user's notifications.
 */
class DholuListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        connected = true
        // Pick up what is already in the shade so the first summary is not empty.
        try {
            activeNotifications?.forEach { handle(it) }
        } catch (_: Exception) {
        }
    }

    override fun onListenerDisconnected() {
        connected = false
        super.onListenerDisconnected()
        // Ask the system to rebind (OEMs sometimes drop listeners).
        try {
            requestRebind(ComponentName(this, DholuListenerService::class.java))
        } catch (_: Exception) {
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) = handle(sbn)

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        pending.remove(sbn.key)
    }

    private fun handle(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName) return
        val n = sbn.notification ?: return
        // Skip group summaries, ongoing (music, navigation, calls) and low-value system rows.
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (n.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        if (n.flags and Notification.FLAG_FOREGROUND_SERVICE != 0) return

        val extras = n.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val big = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val text = (big ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()).orEmpty()
        if (title.isBlank() && text.isBlank()) return

        n.contentIntent?.let { remember(sbn.key, it) }

        val appName = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(sbn.packageName, 0)).toString()
        } catch (_: Exception) {
            sbn.packageName
        }
        val messaging = n.category == Notification.CATEGORY_MESSAGE ||
            extras.getString(Notification.EXTRA_TEMPLATE)?.contains("MessagingStyle") == true

        val sensitive = SensitiveGuard.kind(title, text)
        val json = JSONObject().apply {
            put("key", sbn.key)
            put("pkg", sbn.packageName)
            put("appName", appName)
            put("title", title)
            put("text", text)
            put("postedAt", sbn.postTime)
            put("messaging", messaging)
            put("hasContentIntent", n.contentIntent != null)
            if (sensitive != null) put("sensitive", sensitive)
        }

        val s = sink
        if (s != null) {
            // Live path: Dart applies its own (tested) filter before storing anything.
            main.post { sink?.success(json.toString()) }
        } else {
            // Offline path: never write sensitive text to disk, and keep text only for apps the
            // user marked important (everything else is only counted).
            if (sensitive != null || !ImportantApps.contains(applicationContext, sbn.packageName)) {
                json.put("text", "").put("title", "")
            }
            NotificationQueue.append(applicationContext, json)
        }
    }

    companion object {
        @Volatile var connected = false
        @Volatile var sink: EventChannel.EventSink? = null
        private val main = Handler(Looper.getMainLooper())
        private const val MAX_PENDING = 300

        /** key -> contentIntent, insertion-ordered and capped. */
        private val pending: MutableMap<String, PendingIntent> = Collections.synchronizedMap(
            object : LinkedHashMap<String, PendingIntent>() {
                override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, PendingIntent>?) = size > MAX_PENDING
            }
        )

        private fun remember(key: String, pi: PendingIntent) {
            pending[key] = pi
        }

        fun intentFor(key: String): PendingIntent? = pending[key]
    }
}
