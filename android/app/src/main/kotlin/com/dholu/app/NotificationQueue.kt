package com.dholu.app

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * Append-only JSON-lines file for notifications that arrive while the Flutter engine
 * is not attached. Dart drains it on start / from the morning-summary worker.
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

    /** Returns all queued entries and clears the file. */
    fun drain(ctx: Context): List<String> = synchronized(lock) {
        val f = file(ctx)
        if (!f.exists()) return emptyList()
        val lines = f.readLines().filter { it.isNotBlank() }
        f.delete()
        lines
    }
}
