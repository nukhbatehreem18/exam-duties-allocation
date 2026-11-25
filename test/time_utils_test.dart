import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/core/time_utils.dart';

void main() {
  final nau = DateTime.utc(2026, 12, 1, 9, 0);
  final gyarah = DateTime.utc(2026, 12, 1, 11, 0);
  final barah = DateTime.utc(2026, 12, 1, 12, 0);

  test('duration integer minutes mein hai', () {
    expect(TimeInterval(nau, gyarah).durationMinutes, 120);
  });

  test('9-11 aur 10-12 overlap karte hain', () {
    final a = TimeInterval(nau, gyarah);
    final b = TimeInterval(DateTime.utc(2026, 12, 1, 10, 0), barah);
    expect(a.overlaps(b), true);
  });

  test('9-11 aur 11-12 overlap NAHI (half-open)', () {
    final a = TimeInterval(nau, gyarah);
    final b = TimeInterval(gyarah, barah);
    expect(a.overlaps(b), false);
  });

  test('formatMinutes 150 ko 2h 30m banata hai', () {
    expect(formatMinutes(150), '2h 30m');
  });
}