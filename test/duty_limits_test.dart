import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/domain/duty_limits.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  const staff = Staff(
    id: 's1',
    name: 'Ali',
    email: 'ali@bahria.edu.pk',
    maxDuties: 2,
    maxMinutes: 240,
  );

  test('allows a duty within both limits', () {
    final r = checkLimits(
      staff: staff,
      currentDuties: 1,
      currentMinutes: 120,
      newDutyMinutes: 120,
    );
    expect(r.allowed, true);
  });

  test('blocks when max duties would be exceeded', () {
    final r = checkLimits(
      staff: staff,
      currentDuties: 2,
      currentMinutes: 60,
      newDutyMinutes: 60,
    );
    expect(r.allowed, false);
    expect(r.reason, 'Maximum number of duties reached');
  });

  test('blocks when max minutes would be exceeded', () {
    final r = checkLimits(
      staff: staff,
      currentDuties: 1,
      currentMinutes: 200,
      newDutyMinutes: 60,
    );
    expect(r.allowed, false);
    expect(r.reason, 'Maximum duty minutes exceeded');
  });
}