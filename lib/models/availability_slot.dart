import '../core/time_utils.dart';

/// Staff ka ek waqt jab wo duty ke liye available hai.
/// Interval half-open [start, end) hai.
class AvailabilitySlot {
  final DateTime start;
  final DateTime end;

  const AvailabilitySlot({required this.start, required this.end});

  TimeInterval get interval => TimeInterval(start, end);

  /// Kya ye slot poora exam ka waqt cover karta hai?
  bool covers(TimeInterval exam) {
    return !start.isAfter(exam.start) && !end.isBefore(exam.end);
  }
}