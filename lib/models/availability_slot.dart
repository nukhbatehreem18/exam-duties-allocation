import '../core/time_utils.dart';

/// A period during which a staff member is available for duty.
/// The interval is half-open: [start, end).
class AvailabilitySlot {
  final DateTime start;
  final DateTime end;

  const AvailabilitySlot({required this.start, required this.end});

  TimeInterval get interval => TimeInterval(start, end);

  /// True if this slot fully covers the exam time.
  bool covers(TimeInterval exam) {
    return !start.isAfter(exam.start) && !end.isBefore(exam.end);
  }
}