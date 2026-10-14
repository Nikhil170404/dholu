package com.dholu.app

/**
 * Last line of defence on the native side: text that is queued to disk while the
 * Flutter engine is not running must never contain an OTP, password or bank
 * transaction body. Mirrors lib/core/sensitive_filter.dart (the Dart filter is the
 * tested reference; this only decides whether to blank the text before queuing).
 */
object SensitiveGuard {
    private val otpWords = Regex(
        "\\b(otp|one[\\s-]?time|verification|verify|passcode|security code|login code|auth(entication)? code|pin|cvv|ओटीपी)\\b",
        RegexOption.IGNORE_CASE
    )
    private val code = Regex("(?<!\\d)(?<!\\d[.,])\\d{4,8}(?!\\d)(?![.,]\\d)")
    private val codeWord = Regex("\\bcode\\b", RegexOption.IGNORE_CASE)
    private val doNotShare = Regex(
        "(do not share|don'?t share|never share|share na kar|kisi se share)",
        RegexOption.IGNORE_CASE
    )
    private val secret = Regex("\\b(password|passwd|passphrase|recovery key)\\b", RegexOption.IGNORE_CASE)
    private val bankVerb = Regex(
        "\\b(debited|credited|withdrawn|deposited|avl\\.?\\s*bal|available balance|a/?c\\.?\\s*(no|xx)|acct|upi ref|txn|utr|neft|imps|rtgs|balance)\\b",
        RegexOption.IGNORE_CASE
    )
    private val amount = Regex("(rs\\.?|inr|₹)\\s*[\\d,]+", RegexOption.IGNORE_CASE)
    private val maskedAcct = Regex("(x{2,}|\\*{2,})\\s*\\d{3,4}", RegexOption.IGNORE_CASE)

    /** Returns "otp", "bank", "secret" or null. */
    fun kind(title: String, text: String): String? {
        val all = "$title $text"
        if (secret.containsMatchIn(all)) return "secret"
        if (code.containsMatchIn(all) &&
            (otpWords.containsMatchIn(all) || doNotShare.containsMatchIn(all) || codeWord.containsMatchIn(all))
        ) return "otp"
        if (bankVerb.containsMatchIn(all) && (amount.containsMatchIn(all) || maskedAcct.containsMatchIn(all))) return "bank"
        return null
    }
}
