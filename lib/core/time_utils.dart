/// Pakistan (Asia/Karachi) ka time zone hamesha +05:00 hai.
const Duration karachiOffset = Duration(hours: 5);

/// Do time intervals half-open [start, end) hote hain.
/// Matlab: start shamil hai, end shamil NAHI hai.
class TimeInterval {
  final DateTime start;
  final DateTime end;

  TimeInterval(this.start, this.end)
      : assert(end.isAfter(start), 'end, start ke baad hona chahiye');

  /// Interval ki lambai integer minutes mein.
  int get durationMinutes => end.difference(start).inMinutes;

  /// Kya ye interval doosre se overlap karta hai?
  /// Half-open rule: agar ek ka end == doosre ka start, to overlap NAHI.
  bool overlaps(TimeInterval other) {
    return start.isBefore(other.end) && other.start.isBefore(end);
  }
}

/// Kisi bhi DateTime ko Karachi ke time mein badalta hai.
DateTime toKarachi(DateTime t) => t.toUtc().add(karachiOffset);

/// Minutes ko "2h 30m" jaisa text banata hai (sirf dikhane ke liye).
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m}m';
}