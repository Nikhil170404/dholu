import 'dart:async';

import '../core/types.dart';
import 'llm.dart';
import 'prompts.dart';

/// Second-pass classification by the on-device model for items the rules are unsure
/// about (brief section 8, step 5). Never runs on sensitive items and never talks to
/// a cloud backend: it only receives a local backend.
class Refiner {
  const Refiner({
    this.lang = Lang.hinglish,
    this.timeout = const Duration(seconds: 25),
  });
  final Lang lang;
  final Duration timeout;

  /// Rules are confident about junk/clear urgent/promo; the middle band goes to the model.
  bool isUncertain(Classification c) {
    if (c.category == Category.otp ||
        c.category == Category.bank ||
        c.category == Category.promo) {
      return false;
    }
    return c.priority == Priority.normal || (c.score >= 1.5 && c.score < 5);
  }

  /// Returns the refined classification, or null to keep the rules result.
  Future<Classification?> refine(
    RawNotification n,
    Classification rules,
    LlmBackend local,
  ) async {
    if (!local.isLocal || !isUncertain(rules)) {
      return null;
    }
    final body = '${n.title}: ${n.text}';
    final trimmed = body.length > 400 ? body.substring(0, 400) : body;
    try {
      final j = await local
          .json([
            ChatTurn.system(classifySystemPrompt(lang)),
            ChatTurn.user(trimmed),
          ], classificationSchema)
          .timeout(timeout);
      final c = parseClassification(j);
      if (c == null) {
        return null;
      }
      return Classification(
        priority: c.priority,
        category: c.category,
        action: c.action,
        summary: c.summary,
        score: rules.score,
      );
    } on TimeoutException {
      return null;
    } on Object {
      return null;
    }
  }
}
