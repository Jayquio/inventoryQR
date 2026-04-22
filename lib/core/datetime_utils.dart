/// Local-date helpers for borrow "needed by" and API datetime display.
class DateTimeUtils {
  DateTimeUtils._();

  static DateTime startOfTodayLocal() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Matches server rule in [request_create.php]: first selectable calendar day
  /// is local today plus three full days (e.g. Mon → earliest Thu).
  static DateTime firstAllowedNeededByDay() {
    return startOfTodayLocal().add(const Duration(days: 3));
  }

  static DateTime? tryParseFlexible(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    try {
      if (s.length >= 19 && (s[10] == ' ' || s[10] == 'T')) {
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
        return DateTime.parse('${s}T00:00:00');
      }
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String formatNeededByForDisplay(String? raw) {
    final dt = tryParseFlexible(raw);
    if (dt == null) return raw?.trim() ?? '';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h24 = dt.hour;
    final m = dt.minute;
    final isPm = h24 >= 12;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ap = isPm ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · '
        '$h12:${m.toString().padLeft(2, '0')} $ap';
  }
}
