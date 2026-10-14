package com.dholu.app

import android.content.Context
import java.io.File

/**
 * The packages the user marked important, written by Dart (lib/native/important_apps_file.dart).
 * While the Flutter engine is not running, text from any other app is blanked before it is
 * queued to disk: Dholu only keeps message text for apps the user chose.
 */
object ImportantApps {
    private const val FILE = "dholu_important_apps.txt" // must match important_apps_file.dart

    @Volatile private var cached: Set<String> = emptySet()
    @Volatile private var loadedAt: Long = -1

    fun contains(ctx: Context, pkg: String): Boolean {
        val f = File(ctx.filesDir, FILE)
        val stamp = if (f.exists()) f.lastModified() else 0L
        if (stamp != loadedAt) {
            cached = if (f.exists()) f.readLines().map { it.trim() }.filter { it.isNotEmpty() }.toSet() else emptySet()
            loadedAt = stamp
        }
        return pkg in cached
    }
}
