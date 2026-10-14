package com.dholu.app

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * Append-only JSON-lines file for notifications that arrive while the Flutter engine
 * is not attached. Dart reads and clears it (lib/native/queue_file.dart) on start and
 * from the morning-summary worker; the file name below must match.
 * Capped so a long-dead app cannot grow it without bound.
 */
object NotificationQueue {
    private const val FILE = "dholu_queue.jsonl"
    private const val MAX_LINES = 500
    private val lock = Any()

    private fun file(ctx: Context) = File(ctx.filesDir, FILE)

    fun append(ctx: Context, json: JSONObject) = synchronized(lock) {
        val f = file(ctx)
        val lines = if (f.exists()) f.readLines().toMutableList() else mutableListOf()
        lines.add(json.toString())
        val kept = if (lines.size > MAX_LINES) lines.takeLast(MAX_LINES) else lines
        f.writeText(kept.joinToString("\n") + "\n")
    }
}
