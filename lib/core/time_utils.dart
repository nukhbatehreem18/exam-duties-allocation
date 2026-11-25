/// Pakistan (Asia/Karachi) is always UTC+05:00 (no daylight saving).
const Duration karachiOffset = Duration(hours: 5);

/// A time interval, treated as half-open: [start, end).
/// The start is included, the end is NOT included.
class TimeInterval {
  final DateTime start;
  final DateTime end;

  TimeInterval(this.start, this.end)
      : assert(end.isAfter(start), 'end must be after start');

  /// Length of the interval in integer minutes.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Half-open rule: if one interval ends exactly when the other
  /// starts, they do NOT overlap.
  bool overlaps(TimeInterval other) {
    return start.isBefore(other.end) && other.start.isBefore(end);
  }
}

/// Converts any DateTime to Karachi time (UTC+05:00).
DateTime toKarachi(DateTime t) => t.toUtc().add(karachiOffset);

/// Formats minutes as text such as "2h 30m" (for display only).
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m}m';
}