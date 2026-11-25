import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/core/time_utils.dart';
import 'package:exam_duties_allocation/models/availability_slot.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  final staff = Staff(
    id: 's1',
    name: 'Ali',
    email: 'ali@bahria.edu.pk',
    maxDuties: 3,
    maxMinutes: 360,
    availability: [
      AvailabilitySlot(
        start: DateTime.utc(2026, 12, 1, 8, 0),
        end: DateTime.utc(2026, 12, 1, 13, 0),
      ),
    ],
  );

  test('available when the exam is inside an availability slot', () {
    final exam = TimeInterval(
      DateTime.utc(2026, 12, 1, 9, 0),
      DateTime.utc(2026, 12, 1, 11, 0),
    );
    expect(staff.isAvailableFor(exam), true);
  });

  test('not available when the exam is outside every slot', () {
    final exam = TimeInterval(
      DateTime.utc(2026, 12, 1, 12, 0),
      DateTime.utc(2026, 12, 1, 14, 0),
    );
    expect(staff.isAvailableFor(exam), false);
  });
}