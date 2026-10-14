import 'types.dart';

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// Finds the first due/deadline date in [text], relative to [now].
/// Understands "kal", "aaj", "tomorrow", "today", "15 Oct", "Oct 15", "15/10".
DateTime? findDueDate(String text, DateTime now) {
  final t = text.toLowerCase();
  final today = DateTime(now.year, now.month, now.day);
  if (RegExp(r'\b(kal|kl|kaal|tomorrow|tmrw)\b').hasMatch(t)) {
    return today.add(const Duration(days: 1));
  }
  if (RegExp(r'\b(aaj|today|tonight)\b').hasMatch(t)) return today;

  DateTime? build(int day, int month) {
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    var d = DateTime(now.year, month, day);
    if (d.isBefore(today.subtract(const Duration(days: 30)))) {
      d = DateTime(now.year + 1, month, day);
    }
    return d;
  }

  final dm = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b',
  ).firstMatch(t);
  if (dm != null) return build(int.parse(dm.group(1)!), _months[dm.group(2)]!);
  final md = RegExp(
    r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s*(\d{1,2})\b',
  ).firstMatch(t);
  if (md != null) return build(int.parse(md.group(2)!), _months[md.group(1)]!);
  final slash = RegExp(r'\b(\d{1,2})/(\d{1,2})\b').firstMatch(t);
  if (slash != null) {
    return build(int.parse(slash.group(1)!), int.parse(slash.group(2)!));
  }
  return null;
}

/// "aaj" / "kal" / "N din mein" (or English).
String relativeDay(DateTime due, DateTime now, Lang lang) {
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
  final en = lang == Lang.english;
  if (days < 0) return en ? 'overdue' : 'nikal gaya';
  if (days == 0) return en ? 'today' : 'aaj';
  if (days == 1) return en ? 'tomorrow' : 'kal';
  return en ? 'in $days days' : '$days din mein';
}
