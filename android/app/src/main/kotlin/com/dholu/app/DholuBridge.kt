package com.dholu.app

import android.app.ActivityManager
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/** MethodChannel "dholu/native" + EventChannel "dholu/notifications". */
class DholuBridge(private val ctx: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    private val worker = Executors.newSingleThreadExecutor()
    private val main = android.os.Handler(android.os.Looper.getMainLooper())

    init {
        MethodChannel(messenger, "dholu/native").setMethodCallHandler(this)
        EventChannel(messenger, "dholu/notifications").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                DholuListenerService.sink = events
            }

            override fun onCancel(args: Any?) {
                DholuListenerService.sink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessGranted" -> result.success(isAccessGranted())
            "openAccessSettings" -> result.success(startSafely(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)))
            "openAppSettings" -> result.success(
                startSafely(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${ctx.packageName}")))
            )
            "openBatterySettings" -> result.success(startSafely(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)))
            "requestRebind" -> {
                try {
                    NotificationListenerService.requestRebind(ComponentName(ctx, DholuListenerService::class.java))
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            "isListenerConnected" -> result.success(DholuListenerService.connected)
            "drainQueue" -> result.success(NotificationQueue.drain(ctx))
            "getInstalledApps" -> worker.execute {
                val apps = installedApps()
                main.post { result.success(apps) }
            }
            "getAppIcon" -> worker.execute {
                val bytes = appIcon(call.argument<String>("pkg") ?: "")
                main.post { result.success(bytes) }
            }
            "fire" -> result.success(fire(call.argument<String>("key"), call.argument<String>("pkg")))
            "launchApp" -> result.success(launchApp(call.argument<String>("pkg") ?: ""))
            "getDeviceSpecs" -> result.success(deviceSpecs())
            "composeEmail" -> result.success(
                composeEmail(
                    call.argument<String>("to").orEmpty(),
                    call.argument<String>("subject").orEmpty(),
                    call.argument<String>("body").orEmpty()
                )
            )
            else -> result.notImplemented()
        }
    }

    private fun startSafely(i: Intent): Boolean = try {
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(i)
        true
    } catch (e: Exception) {
        false
    }

    private fun isAccessGranted(): Boolean {
        val flat = Settings.Secure.getString(ctx.contentResolver, "enabled_notification_listeners") ?: return false
        return flat.split(":").any { ComponentName.unflattenFromString(it)?.packageName == ctx.packageName }
    }

    private fun installedApps(): List<Map<String, String>> {
        val pm = ctx.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val flags = 0
        val infos = if (Build.VERSION.SDK_INT >= 33) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION") pm.queryIntentActivities(intent, flags)
        }
        return infos
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != ctx.packageName }
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }
            .map { mapOf("pkg" to it.first, "name" to it.second) }
    }

    /** 96px PNG, for the apps list. */
    private fun appIcon(pkg: String): ByteArray? = try {
        val d = ctx.packageManager.getApplicationIcon(pkg)
        val size = 96
        val bmp = if (d is BitmapDrawable && d.bitmap != null) {
            Bitmap.createScaledBitmap(d.bitmap, size, size, true)
        } else {
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also {
                val c = Canvas(it)
                d.setBounds(0, 0, size, size)
                d.draw(c)
            }
        }
        ByteArrayOutputStream().also { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
    } catch (e: Exception) {
        null
    }

    /**
     * Redirect: fire the original notification's contentIntent so the source app
     * opens at the right place. Falls back to the app's launcher activity.
     */
    private fun fire(key: String?, pkg: String?): String {
        val pi = key?.let { DholuListenerService.intentFor(it) }
        if (pi != null) {
            try {
                if (Build.VERSION.SDK_INT >= 34) {
                    val opts = ActivityOptions.makeBasic()
                        .setPendingIntentBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
                    pi.send(opts.toBundle())
                } else {
                    pi.send()
                }
                return "intent"
            } catch (e: PendingIntent.CanceledException) {
                // fall through to launch
            } catch (e: Exception) {
            }
        }
        return if (pkg != null && launchApp(pkg)) "launch" else "failed"
    }

    private fun launchApp(pkg: String): Boolean {
        val i = ctx.packageManager.getLaunchIntentForPackage(pkg) ?: return false
        return startSafely(i)
    }

    private fun deviceSpecs(): Map<String, Any?> {
        val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }
        val stat = StatFs(ctx.filesDir.absolutePath)
        return mapOf(
            "totalRamMb" to (mi.totalMem / (1024 * 1024)),
            "availRamMb" to (mi.availMem / (1024 * 1024)),
            "freeStorageMb" to (stat.availableBytes / (1024 * 1024)),
            "cores" to Runtime.getRuntime().availableProcessors(),
            "abis" to Build.SUPPORTED_ABIS.toList(),
            "sdk" to Build.VERSION.SDK_INT,
            "lowRam" to am.isLowRamDevice,
            "soc" to if (Build.VERSION.SDK_INT >= 31) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else Build.HARDWARE,
            "model" to "${Build.MANUFACTURER} ${Build.MODEL}"
        )
    }

    /** Opens the user's email app with a prefilled draft. Never sends anything. */
    private fun composeEmail(to: String, subject: String, body: String): Boolean {
        val i = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
            if (to.isNotBlank()) putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        return startSafely(i)
    }
}
