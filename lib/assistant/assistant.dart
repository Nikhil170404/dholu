import '../ai/llm.dart';
import '../core/digest.dart';
import '../core/types.dart';
import 'web_search.dart';

sealed class AssistantEvent {
  const AssistantEvent();
}

class SearchStarted extends AssistantEvent {
  const SearchStarted(this.query);
  final String query;
}

class SearchDone extends AssistantEvent {
  const SearchDone(this.results);
  final List<SearchResult> results;
}

class SearchFailed extends AssistantEvent {
  const SearchFailed(this.message);
  final String message;
}

class Token extends AssistantEvent {
  const Token(this.text);
  final String text;
}

/// The user must confirm before notification context is sent to a cloud model.
class ConsentRequired implements Exception {
  @override
  String toString() =>
      'Cloud model needs your OK before it can see your messages.';
}

enum Tone { normal, short, formal, english }

class EmailDraft {
  const EmailDraft({required this.subject, required this.body});
  final String subject;
  final String body;
}

String _personaPrompt(Lang lang) =>
    '''
You are Dholu, a friendly, careful assistant inside a notification app for Indian users.
Reply in ${lang == Lang.english ? 'clear English' : 'simple Hinglish (Hindi in Roman script) unless the user writes in English'}.
Be short and practical. If you are not sure, say so. You cannot send messages, pay, or open apps yourself:
you only suggest or draft, and the user decides.''';

class AssistantService {
  AssistantService({this.lang = Lang.hinglish});
  final Lang lang;

  /// Chat with optional web search. The search query is the user's own text, never notification content.
  Stream<AssistantEvent> chat(
    LlmBackend llm,
    List<ChatTurn> history,
    String userText, {
    WebSearch? web,
  }) async* {
    var system = _personaPrompt(lang);
    if (web != null) {
      final q = buildQuery(userText);
      if (q.isNotEmpty) {
        yield SearchStarted(q);
        try {
          final results = await web.search(q);
          yield SearchDone(results);
          if (results.isNotEmpty) {
            system +=
                '\n\nWeb results (use them, cite like [1], say if they do not answer the question):\n${_format(results)}';
          }
        } on Object catch (e) {
          yield SearchFailed(e.toString());
        }
      }
    }
    final turns = [
      ChatTurn.system(system),
      ...history,
      ChatTurn.user(userText),
    ];
    await for (final d in llm.chat(turns, maxTokens: 600, temperature: 0.6)) {
      yield Token(d);
    }
  }

  static String _format(List<SearchResult> rs) => [
    for (var i = 0; i < rs.length; i++)
      '[${i + 1}] ${rs[i].title} - ${rs[i].snippet} (${rs[i].url})',
  ].join('\n');

  // ---- drafting ----

  static String _context(List<StoredEvent> ctx) {
    final lines = [
      for (final e in ctx.reversed.take(8))
        if (e.text.isNotEmpty)
          '${e.sender}: ${e.text.length > 300 ? e.text.substring(0, 300) : e.text}',
    ];
    return lines.join('\n');
  }

  String _toneLine(Tone t) => switch (t) {
    Tone.normal => '',
    Tone.short => 'Keep it very short (1-2 lines).',
    Tone.formal => 'Use a polite, formal tone.',
    Tone.english => 'Write in English.',
  };

  /// Drafts an email using stored message context. Throws [ConsentRequired] when [llm] is
  /// not on-device, context is non-empty and the user has not confirmed.
  Future<EmailDraft> draftEmail(
    LlmBackend llm, {
    required String instruction,
    String recipientName = '',
    List<StoredEvent> context = const [],
    Tone tone = Tone.normal,
    bool cloudConsent = false,
  }) async {
    final ctx = _context(context);
    if (!llm.isLocal && ctx.isNotEmpty && !cloudConsent) {
      throw ConsentRequired();
    }
    final system =
        '${_personaPrompt(lang)}\nYou write emails. Output JSON with "subject" and "body". '
        'Body: greeting, clear message, polite closing. Do not invent facts, dates or amounts that are not in the context or instruction. ${_toneLine(tone)}';
    final user = StringBuffer()
      ..writeln('Task: $instruction')
      ..writeln(recipientName.isEmpty ? '' : 'To: $recipientName')
      ..writeln(ctx.isEmpty ? '' : 'Recent messages for context:\n$ctx');
    final turns = [
      ChatTurn.system(system),
      ChatTurn.user(user.toString().trim()),
    ];
    const schema = {
      'type': 'object',
      'properties': {
        'subject': {'type': 'string'},
        'body': {'type': 'string'},
      },
      'required': ['subject', 'body'],
      'additionalProperties': false,
    };
    final j = await llm.json(turns, schema, maxTokens: 500);
    if (j != null &&
        j['subject'] is String &&
        j['body'] is String &&
        (j['body'] as String).trim().isNotEmpty) {
      return EmailDraft(
        subject: (j['subject'] as String).trim(),
        body: (j['body'] as String).trim(),
      );
    }
    // Fallback: plain text with a "Subject:" line.
    final text = await llm.complete([
      ...turns,
      const ChatTurn.user(
        'Reply as plain text. First line "Subject: ...", then the body.',
      ),
    ], maxTokens: 500);
    return parseEmailText(text);
  }

  /// Drafts a short chat reply to [message] (screen 5). Context is the same conversation.
  Future<String> draftReply(
    LlmBackend llm, {
    required String sender,
    required String message,
    List<StoredEvent> context = const [],
    Tone tone = Tone.normal,
    bool cloudConsent = false,
  }) async {
    final ctx = _context(context);
    if (!llm.isLocal &&
        (ctx.isNotEmpty || message.isNotEmpty) &&
        !cloudConsent) {
      throw ConsentRequired();
    }
    final system =
        '${_personaPrompt(lang)}\nWrite ONE short chat reply the user can send. No quotes, no explanation. ${_toneLine(tone)}';
    final user =
        'Message from $sender: $message${ctx.isEmpty ? '' : '\nEarlier:\n$ctx'}';
    final out = await llm.complete(
      [ChatTurn.system(system), ChatTurn.user(user)],
      maxTokens: 160,
      temperature: 0.6,
    );
    return out.replaceAll(RegExp(r'^["“]|["”]$'), '').trim();
  }
}

EmailDraft parseEmailText(String text) {
  final lines = text.trim().split('\n');
  var subject = '';
  var start = 0;
  if (lines.isNotEmpty && lines.first.toLowerCase().startsWith('subject:')) {
    subject = lines.first.substring(8).trim();
    start = 1;
  }
  final body = lines.skip(start).join('\n').trim();
  return EmailDraft(subject: subject, body: body);
}
