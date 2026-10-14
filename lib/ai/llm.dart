import 'dart:convert';

enum TurnRole { system, user, assistant }

class ChatTurn {
  const ChatTurn(this.role, this.text);
  const ChatTurn.system(this.text) : role = TurnRole.system;
  const ChatTurn.user(this.text) : role = TurnRole.user;
  const ChatTurn.assistant(this.text) : role = TurnRole.assistant;
  final TurnRole role;
  final String text;
}

/// One text-generation engine (on-device or cloud).
abstract class LlmBackend {
  /// Short label for the UI ("Gemma 3 1B (on this phone)").
  String get label;

  /// True when nothing leaves the phone.
  bool get isLocal;

  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  });

  Future<String> complete(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.4,
  }) async {
    final b = StringBuffer();
    await for (final d in chat(
      turns,
      maxTokens: maxTokens,
      temperature: temperature,
    )) {
      b.write(d);
    }
    return b.toString().trim();
  }

  /// JSON-constrained generation. Local models use grammar decoding (always valid);
  /// others fall back to prompt + tolerant parsing. Returns null if no valid JSON.
  Future<Map<String, dynamic>?> json(
    List<ChatTurn> turns,
    Map<String, dynamic> schema, {
    int maxTokens = 160,
  }) async {
    final text = await complete(turns, maxTokens: maxTokens, temperature: 0.1);
    return extractJsonObject(text);
  }

  /// Stops an in-flight generation (no-op for backends that cannot).
  void cancel() {}

  Future<void> dispose();
}

/// Pulls the first {...} object out of model text (handles ```json fences and chatter).
Map<String, dynamic>? extractJsonObject(String text) {
  final start = text.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inStr = false;
  var esc = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (inStr) {
      if (esc) {
        esc = false;
      } else if (ch == r'\') {
        esc = true;
      } else if (ch == '"') {
        inStr = false;
      }
      continue;
    }
    if (ch == '"') {
      inStr = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        try {
          final v = jsonDecode(text.substring(start, i + 1));
          return v is Map<String, dynamic> ? v : null;
        } on FormatException {
          return null;
        }
      }
    }
  }
  return null;
}

/// Keeps the system prompt and as many recent turns as fit in roughly [maxTokens]
/// (estimated at 3.5 chars/token). Always keeps the last user turn.
List<ChatTurn> fitTurns(List<ChatTurn> turns, int maxTokens) {
  final budget = (maxTokens * 3.5).floor();
  final system = turns.where((t) => t.role == TurnRole.system).toList();
  final rest = turns.where((t) => t.role != TurnRole.system).toList();
  var used = system.fold<int>(0, (s, t) => s + t.text.length);
  final kept = <ChatTurn>[];
  for (final t in rest.reversed) {
    if (kept.isNotEmpty && used + t.text.length > budget) {
      break;
    }
    var text = t.text;
    if (kept.isEmpty && used + text.length > budget) {
      // Last turn alone is too long: keep its tail.
      text = text.substring(
        text.length - (budget - used).clamp(200, text.length),
      );
    }
    kept.add(ChatTurn(t.role, text));
    used += text.length;
  }
  return [...system, ...kept.reversed];
}
