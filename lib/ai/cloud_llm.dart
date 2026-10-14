import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm.dart';

/// Optional BYOK backend for any OpenAI-compatible endpoint. Used ONLY for chat / email
/// drafting the user starts; notification text is never sent here automatically.
class CloudLlm extends LlmBackend {
  CloudLlm({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    final u = Uri.tryParse(baseUrl);
    if (u == null || u.scheme != 'https') {
      throw ArgumentError('Cloud endpoint must use https.');
    }
  }

  final String baseUrl;
  final String model;
  final String apiKey;
  final http.Client _client;

  @override
  String get label => 'Cloud: $model';
  @override
  bool get isLocal => false;

  @override
  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) async* {
    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
    );
    final req = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': [
          for (final t in turns) {'role': t.role.name, 'content': t.text},
        ],
      });
    final res = await _client.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      throw CloudLlmException(res.statusCode, _short(body));
    }
    var buf = '';
    await for (final chunk in res.stream.transform(utf8.decoder)) {
      buf += chunk;
      while (true) {
        final nl = buf.indexOf('\n');
        if (nl < 0) {
          break;
        }
        final line = buf.substring(0, nl).trim();
        buf = buf.substring(nl + 1);
        if (!line.startsWith('data:')) {
          continue;
        }
        final data = line.substring(5).trim();
        if (data == '[DONE]') {
          return;
        }
        try {
          final j = jsonDecode(data) as Map<String, dynamic>;
          final delta = (j['choices'] as List).first['delta']?['content'];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
        } on Object {
          // ignore keep-alive / malformed lines
        }
      }
    }
  }

  static String _short(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return (m['error']?['message'] ?? body).toString();
    } on Object {
      return body.length > 200 ? body.substring(0, 200) : body;
    }
  }

  @override
  Future<void> dispose() async => _client.close();
}

class CloudLlmException implements Exception {
  CloudLlmException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() =>
      status == 401 ? 'Invalid API key' : 'Cloud model error $status: $message';
}
