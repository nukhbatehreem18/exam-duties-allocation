import '../core/time_utils.dart';

/// One exam session that needs invigilators.
/// The time is half-open: [start, end).
class ExamSession {
  final String id;
  final String course;
  final String room;
  final DateTime start;
  final DateTime end;
  final int requiredInvigilators;

  const ExamSession({
    required this.id,
    required this.course,
    required this.room,
    required this.start,
    required this.end,
    required this.requiredInvigilators,
  });

  TimeInterval get interval => TimeInterval(start, end);

  /// Duration in integer minutes (calculated, never typed by the user).
  int get durationMinutes => end.difference(start).inMinutes;
}