/// Always-first filter (brief section 8, step 2). OTPs, passwords and bank
/// transaction bodies are never stored; only a placeholder is kept.
enum SensitiveKind { otp, bank, secret }

class FilterResult {
  const FilterResult.clean(this.text) : sensitive = false, kind = null;
  const FilterResult.redacted(this.kind, this.text) : sensitive = true;
  final bool sensitive;
  final SensitiveKind? kind;

  /// Original text when clean, otherwise a safe placeholder.
  final String text;
}

class SensitiveFilter {
  const SensitiveFilter();

  static final _otpWords = RegExp(
    r'\b(otp|one[\s-]?time|verification|verify|passcode|security code|login code|auth(?:entication)? code|pin|cvv|ओटीपी)\b',
    caseSensitive: false,
  );
  static final _code = RegExp(r'(?<!\d)(?<!\d[.,])\d{4,8}(?!\d)(?![.,]\d)');
  static final _codeWord = RegExp(r'\bcode\b', caseSensitive: false);
  static final _doNotShare = RegExp(
    r"(do not share|don'?t share|never share|share na kar|kisi se share)",
    caseSensitive: false,
  );
  static final _secret = RegExp(
    r'\b(password|passwd|passphrase|recovery key)\b',
    caseSensitive: false,
  );

  // Bank transaction messages (not bills): money moved or balance shown.
  static final _bankVerb = RegExp(
    r'\b(debited|credited|withdrawn|deposited|avl\.?\s*bal|available balance|a/?c\.?\s*(no|xx)|acct|upi ref|txn|utr|neft|imps|rtgs|balance)\b',
    caseSensitive: false,
  );
  static final _amount = RegExp(
    r'(rs\.?|inr|₹)\s*[\d,]+',
    caseSensitive: false,
  );
  static final _maskedAcct = RegExp(
    r'(x{2,}|\*{2,})\s*\d{3,4}',
    caseSensitive: false,
  );

  FilterResult apply(String title, String text) {
    final all = '$title $text';
    if (_secret.hasMatch(all)) {
      return const FilterResult.redacted(
        SensitiveKind.secret,
        'Sensitive message',
      );
    }
    final hasCode = _code.hasMatch(all);
    if (hasCode &&
        (_otpWords.hasMatch(all) ||
            _doNotShare.hasMatch(all) ||
            _codeWord.hasMatch(all))) {
      return const FilterResult.redacted(SensitiveKind.otp, 'OTP received');
    }
    if (_bankVerb.hasMatch(all) &&
        (_amount.hasMatch(all) || _maskedAcct.hasMatch(all))) {
      return const FilterResult.redacted(SensitiveKind.bank, 'Bank message');
    }
    return FilterResult.clean(text);
  }
}
