import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dholu/ai/llm.dart';
import 'package:dholu/assistant/assistant.dart';
import 'package:dholu/assistant/web_search.dart';
import 'package:dholu/core/digest.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/settings/settings.dart';

class Fake extends LlmBackend {
  Fake({this.local = true, this.reply = 'ok', this.j});
  final bool local;
  final String reply;
  final Map<String, dynamic>? j;
  List<ChatTurn>? lastTurns;
  @override
  String get label => 'f';
  @override
  bool get isLocal => local;
  @override
  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) {
    lastTurns = turns;
    return Stream.value(reply);
  }

  @override
  Future<Map<String, dynamic>?> json(
    List<ChatTurn> turns,
    Map<String, dynamic> schema, {
    int maxTokens = 160,
  }) async {
    lastTurns = turns;
    return j;
  }

  @override
  Future<void> dispose() async {}
}

StoredEvent ev(String sender, String text) => StoredEvent(
  id: 1,
  key: 'k',
  pkg: 'p',
  appName: 'a',
  sender: sender,
  text: text,
  postedAt: DateTime(2026, 10, 14),
  classification: const Classification(
    priority: Priority.important,
    category: Category.message,
    action: NotifAction.reply,
    summary: 's',
  ),
);

class FakeSearch implements WebSearch {
  FakeSearch({this.fail = false});
  final bool fail;
  String? q;
  @override
  Future<List<SearchResult>> search(String query, {int limit = 5}) async {
    q = query;
    if (fail) {
      throw SearchException('down');
    }
    return const [
      SearchResult('Kolkata weather', 'https://w.example/kol', 'Sunny 31C'),
    ];
  }
}

void main() {
  group('web search parsers', () {
    test('DuckDuckGo html', () {
      const html = '''
<div class="result"><a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fa&amp;rut=x">Example <b>A</b></a>
<a class="result__snippet" href="x">First &amp; best <b>result</b></a></div>
<div class="result"><a class="result__a" href="https://direct.example/b">Direct B</a><a class="result__snippet" href="x">Second</a></div>''';
      final r = DuckDuckGoSearch.parseDuckDuckGo(html, 5);
      expect(r.length, 2);
      expect(r[0].url, 'https://example.com/a');
      expect(r[0].title, 'Example A');
      expect(r[0].snippet, 'First & best result');
      expect(r[1].url, 'https://direct.example/b');
    });
    test('Brave json + key header', () async {
      late http.BaseRequest seen;
      final c = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'web': {
              'results': [
                {
                  'title': 'T <b>1</b>',
                  'url': 'https://a.com',
                  'description': 'D',
                },
              ],
            },
          }),
          200,
        );
      });
      final r = await BraveSearch('KEY', c).search('weather');
      expect(r.single.title, 'T 1');
      expect(seen.headers['X-Subscription-Token'], 'KEY');
      expect(seen.url.host, 'api.search.brave.com');
    });
    test('Brave bad key', () async {
      final c = MockClient((_) async => http.Response('', 401));
      expect(
        BraveSearch('bad', c).search('x'),
        throwsA(isA<SearchException>()),
      );
    });
    test('SearXNG json and https requirement', () async {
      final c = MockClient((req) async {
        expect(req.url.queryParameters['format'], 'json');
        return http.Response(
          jsonEncode({
            'results': [
              {'title': 'S', 'url': 'https://s.com', 'content': 'C'},
            ],
          }),
          200,
        );
      });
      expect(
        (await SearxngSearch('https://sx.example/', c).search('q'))
            .single
            .snippet,
        'C',
      );
      expect(
        SearxngSearch('http://sx.example').search('q'),
        throwsA(isA<SearchException>()),
      );
    });
    test('web search is off by default and gated by settings', () {
      expect(buildWebSearch(const Settings()), isNull);
      expect(
        buildWebSearch(const Settings(webSearch: true)),
        isA<DuckDuckGoSearch>(),
      );
      expect(
        buildWebSearch(
          const Settings(webSearch: true, searchProvider: SearchProvider.brave),
        ),
        isNull,
      ); // no key
      expect(
        buildWebSearch(
          const Settings(webSearch: true, searchProvider: SearchProvider.brave),
          braveKey: 'k',
        ),
        isA<BraveSearch>(),
      );
    });
    test('buildQuery strips filler and caps length', () {
      expect(buildQuery('please Kolkata weather batao'), 'Kolkata weather');
      expect(buildQuery('a' * 300).length, 120);
    });
  });

  group('AssistantService.chat', () {
    test(
      'searches with the user text, injects results, streams tokens',
      () async {
        final llm = Fake(reply: 'Dhoop hai [1]');
        final web = FakeSearch();
        final events = await AssistantService()
            .chat(llm, const [], 'Kolkata weather aaj', web: web)
            .toList();
        expect(web.q, 'Kolkata weather aaj');
        expect(
          events.whereType<SearchStarted>().single.query,
          'Kolkata weather aaj',
        );
        expect(
          events.whereType<Token>().map((e) => e.text).join(),
          'Dhoop hai [1]',
        );
        expect(llm.lastTurns!.first.text, contains('Sunny 31C'));
      },
    );
    test('search failure does not break the chat', () async {
      final events = await AssistantService()
          .chat(Fake(), const [], 'hello', web: FakeSearch(fail: true))
          .toList();
      expect(events.whereType<SearchFailed>().length, 1);
      expect(events.whereType<Token>().length, 1);
    });
    test('no web object -> no search', () async {
      final events = await AssistantService()
          .chat(Fake(), const [], 'hello')
          .toList();
      expect(events.whereType<SearchStarted>(), isEmpty);
    });
  });

  group('drafting', () {
    test('email uses message context and returns subject/body', () async {
      final llm = Fake(
        j: {
          'subject': 'Report update',
          'body': 'Hi Sir,\nReport 10 baje tak bhej dunga.\nRegards',
        },
      );
      final d = await AssistantService().draftEmail(
        llm,
        instruction: 'Anil sir ko report ka update do',
        recipientName: 'Anil Sir',
        context: [ev('Anil Sir', 'report 10 baje tak bhejna')],
      );
      expect(d.subject, 'Report update');
      expect(llm.lastTurns!.last.text, contains('report 10 baje tak bhejna'));
      expect(llm.lastTurns!.last.text, contains('Anil Sir'));
    });
    test('falls back to plain text parsing', () async {
      final llm = Fake(j: null, reply: 'Subject: Hello\nDear Ravi,\nThanks.');
      final d = await AssistantService().draftEmail(
        llm,
        instruction: 'thank ravi',
      );
      expect(d.subject, 'Hello');
      expect(d.body, startsWith('Dear Ravi'));
    });
    test('cloud backend needs explicit consent when context is sent', () async {
      final cloud = Fake(local: false, j: {'subject': 's', 'body': 'b'});
      final svc = AssistantService();
      expect(
        svc.draftEmail(
          cloud,
          instruction: 'x',
          context: [ev('A', 'private text')],
        ),
        throwsA(isA<ConsentRequired>()),
      );
      expect(
        (await svc.draftEmail(
          cloud,
          instruction: 'x',
          context: [ev('A', 'private text')],
          cloudConsent: true,
        )).subject,
        's',
      );
      // no context -> nothing private to send -> no consent needed
      expect((await svc.draftEmail(cloud, instruction: 'x')).subject, 's');
    });
    test(
      'reply draft: tone applied, quotes stripped, consent enforced',
      () async {
        final llm = Fake(reply: '"Haan, 10 baje tak bhej dunga"');
        final r = await AssistantService().draftReply(
          llm,
          sender: 'Anil Sir',
          message: 'report bhejna',
          tone: Tone.short,
        );
        expect(r, 'Haan, 10 baje tak bhej dunga');
        expect(llm.lastTurns!.first.text, contains('very short'));
        expect(
          AssistantService().draftReply(
            Fake(local: false),
            sender: 'a',
            message: 'm',
          ),
          throwsA(isA<ConsentRequired>()),
        );
      },
    );
    test('parseEmailText handles missing subject', () {
      expect(parseEmailText('Just a body').subject, '');
      expect(parseEmailText('Just a body').body, 'Just a body');
    });
  });
}
