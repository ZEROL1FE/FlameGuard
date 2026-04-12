
String getRemainingTimeString(int startH, int startM, int endH, int endM, DateTime now) {
  final start = DateTime(now.year, now.month, now.day, startH, startM);
  final end = DateTime(now.year, now.month, now.day, endH, endM);
  
  var effectiveEnd = end;
  if (end.isBefore(start)) {
    effectiveEnd = end.add(const Duration(days: 1));
  }

  if (now.isBefore(start)) {
    final diff = start.difference(now);
    return 'Starts in ${_formatDiff(diff)}';
  } else if (now.isBefore(effectiveEnd)) {
    final diff = effectiveEnd.difference(now);
    return 'Ends in ${_formatDiff(diff)}';
  } else {
    final nextStart = start.add(const Duration(days: 1));
    final diff = nextStart.difference(now);
    return 'Starts in ${_formatDiff(diff)}';
  }
}

String getTimerString(int startH, int startM, int endH, int endM, DateTime now) {
  final start = DateTime(now.year, now.month, now.day, startH, startM);
  final end = DateTime(now.year, now.month, now.day, endH, endM);
  
  var effectiveEnd = end;
  if (end.isBefore(start)) {
    effectiveEnd = end.add(const Duration(days: 1));
  }

  Duration diff;
  if (now.isBefore(start)) {
    diff = start.difference(now);
  } else if (now.isBefore(effectiveEnd)) {
    diff = effectiveEnd.difference(now);
  } else {
    final nextStart = start.add(const Duration(days: 1));
    diff = nextStart.difference(now);
  }
  return _formatDiff(diff);
}

String _formatDiff(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) {
    return '${h}h ${m}m';
  }
  return '${m}m';
}
