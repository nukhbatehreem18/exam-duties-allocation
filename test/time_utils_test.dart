import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/core/time_utils.dart';

void main() {
  final nine = DateTime.utc(2026, 12, 1, 9, 0);
  final eleven = DateTime.utc(2026, 12, 1, 11, 0);
  final twelve = DateTime.utc(2026, 12, 1, 12, 0);

  test('duration is stored in integer minutes', () {
    expect(TimeInterval(nine, eleven).durationMinutes, 120);
  });

  test('09:00-11:00 and 10:00-12:00 overlap', () {
    final a = TimeInterval(nine, eleven);
    final b = TimeInterval(DateTime.utc(2026, 12, 1, 10, 0), twelve);
    expect(a.overlaps(b), true);
  });

  test('09:00-11:00 and 11:00-12:00 do NOT overlap (half-open)', () {
    final a = TimeInterval(nine, eleven);
    final b = TimeInterval(eleven, twelve);
    expect(a.overlaps(b), false);
  });

  test('formatMinutes turns 150 into 2h 30m', () {
    expect(formatMinutes(150), '2h 30m');
  });
}