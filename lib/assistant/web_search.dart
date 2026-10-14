import 'dart:convert';

import 'package:http/http.dart' as http;

import '../settings/settings.dart';

class SearchResult {
  const SearchResult(this.title, this.url, this.snippet);
  final String title;
  final String url;
  final String snippet;
}

class SearchException implements Exception {
  SearchException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class WebSearch {
  Future<List<SearchResult>> search(String query, {int limit = 5});
}

String stripHtml(String s) => s
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#x27;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Search terms only: strips filler like "search karo" and caps length.
String buildQuery(String userText) {
  var q = userText.trim().replaceAll(RegExp(r'\s+'), ' ');
  q = q
      .replaceAll(
        RegExp(
          r'\b(please|plz|search karo|google karo|dhundo|batao|bata do|web par dekho)\b',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
  q = q.replaceAll(RegExp(r'\s+'), ' ');
  return q.length > 120 ? q.substring(0, 120) : q;
}

/// DuckDuckGo HTML endpoint: no key needed. HTML structure can change; parsing is lenient
/// and errors are reported instead of crashing.
class DuckDuckGoSearch implements WebSearch {
  DuckDuckGoSearch([http.Client? c]) : _c = c ?? http.Client();
  final http.Client _c;

  @override
  Future<List<SearchResult>> search(String query, {int limit = 5}) async {
    final res = await _c
        .post(
          Uri.parse('https://html.duckduckgo.com/html/'),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Android) Dholu',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'q': query},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw SearchException('Search failed (${res.statusCode}).');
    }
    return parseDuckDuckGo(res.body, limit);
  }

  static List<SearchResult> parseDuckDuckGo(String html, int limit) {
    final out = <SearchResult>[];
    final link = RegExp(
      r'<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final snip = RegExp(
      r'<a[^>]*class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final links = link.allMatches(html).toList();
    final snips = snip.allMatches(html).toList();
    for (var i = 0; i < links.length && out.length < limit; i++) {
      var href = links[i].group(1)!.replaceAll('&amp;', '&');
      if (href.startsWith('//')) {
        href = 'https:$href';
      }
      final uddg = Uri.tryParse(href)?.queryParameters['uddg'];
      final url = uddg ?? href;
      if (!url.startsWith('http')) {
        continue;
      }
      out.add(
        SearchResult(
          stripHtml(links[i].group(2)!),
          url,
          i < snips.length ? stripHtml(snips[i].group(1)!) : '',
        ),
      );
    }
    return out;
  }
}

class BraveSearch implements WebSearch {
  BraveSearch(this.apiKey, [http.Client? c]) : _c = c ?? http.Client();
  final String apiKey;
  final http.Client _c;

  @override
  Future<List<SearchResult>> search(String query, {int limit = 5}) async {
    final uri = Uri.https('api.search.brave.com', '/res/v1/web/search', {
      'q': query,
      'count': '$limit',
    });
    final res = await _c
        .get(
          uri,
          headers: {
            'X-Subscription-Token': apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw SearchException('Brave API key was rejected.');
    }
    if (res.statusCode != 200) {
      throw SearchException('Search failed (${res.statusCode}).');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (j['web']?['results'] as List?) ?? const [];
    return [
      for (final r in results.take(limit))
        SearchResult(
          stripHtml('${r['title']}'),
          '${r['url']}',
          stripHtml('${r['description'] ?? ''}'),
        ),
    ];
  }
}

class SearxngSearch implements WebSearch {
  SearxngSearch(this.baseUrl, [http.Client? c]) : _c = c ?? http.Client();
  final String baseUrl;
  final http.Client _c;

  @override
  Future<List<SearchResult>> search(String query, {int limit = 5}) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null || base.scheme != 'https') {
      throw SearchException('SearXNG address must start with https://');
    }
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/search',
      queryParameters: {'q': query, 'format': 'json'},
    );
    final res = await _c.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw SearchException(
        'Search failed (${res.statusCode}). Is JSON output enabled on your SearXNG?',
      );
    }
    final results = (jsonDecode(res.body)['results'] as List?) ?? const [];
    return [
      for (final r in results.take(limit))
        SearchResult(
          stripHtml('${r['title']}'),
          '${r['url']}',
          stripHtml('${r['content'] ?? ''}'),
        ),
    ];
  }
}

WebSearch? buildWebSearch(Settings s, {String? braveKey, http.Client? client}) {
  if (!s.webSearch) {
    return null;
  }
  switch (s.searchProvider) {
    case SearchProvider.duckduckgo:
      return DuckDuckGoSearch(client);
    case SearchProvider.brave:
      return braveKey == null || braveKey.isEmpty
          ? null
          : BraveSearch(braveKey, client);
    case SearchProvider.searxng:
      return s.searxngUrl.isEmpty ? null : SearxngSearch(s.searxngUrl, client);
  }
}
