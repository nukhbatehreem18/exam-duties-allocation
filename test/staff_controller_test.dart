import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/features/staff/staff_controller.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  test('add, update and remove work', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(staffProvider.notifier);
    final initial = container.read(staffProvider).length;

    const newStaff = Staff(
      id: 'x1',
      name: 'Test',
      email: 't@bahria.edu.pk',
      maxDuties: 2,
      maxMinutes: 120,
    );

    controller.add(newStaff);
    expect(container.read(staffProvider).length, initial + 1);

    controller.update(const Staff(
      id: 'x1',
      name: 'Renamed',
      email: 't@bahria.edu.pk',
      maxDuties: 2,
      maxMinutes: 120,
    ));
    expect(
      container.read(staffProvider).firstWhere((s) => s.id == 'x1').name,
      'Renamed',
    );

    controller.remove('x1');
    expect(container.read(staffProvider).length, initial);
  });
}