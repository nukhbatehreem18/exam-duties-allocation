import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/features/allocation/allocation_controller.dart';
import 'package:exam_duties_allocation/features/exams/exam_controller.dart';
import 'package:exam_duties_allocation/features/staff/staff_controller.dart';
import 'package:exam_duties_allocation/models/availability_slot.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  // The sample data has 2 staff (s1, s2) and 2 exams (e1 needs 2, e2 needs 1)
  // on 14 Dec 2026, so there are 3 invigilator slots in total.
  AvailabilitySlot wholeDay() => AvailabilitySlot(
        start: DateTime(2026, 12, 14, 8, 0),
        end: DateTime(2026, 12, 14, 14, 0),
      );

  test('no allocation exists at the start', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(allocationProvider), isNull);
  });

  test('with no availability every slot is a vacancy', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final error = c.read(allocationProvider.notifier).run();
    final run = c.read(allocationProvider)!;

    expect(error, isNull);
    expect(run.result.duties, isEmpty);
    expect(run.result.vacancies.length, 3);
  });

  test('with availability every slot is filled', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    for (final id in ['s1', 's2']) {
      c.read(staffProvider.notifier).addSlot(id, wholeDay());
    }
    c.read(allocationProvider.notifier).run();
    final run = c.read(allocationProvider)!;

    expect(run.result.duties.length, 3);
    expect(run.result.vacancies, isEmpty);
  });

  test('allocation becomes outdated when staff data changes', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(allocationProvider.notifier).run();
    final run = c.read(allocationProvider)!;
    expect(
      run.isOutdatedFor(c.read(staffProvider), c.read(examProvider)),
      false,
    );

    c.read(staffProvider.notifier).add(const Staff(
          id: 'new',
          name: 'New',
          email: 'new@bahria.edu.pk',
          maxDuties: 2,
          maxMinutes: 240,
        ));
    expect(
      run.isOutdatedFor(c.read(staffProvider), c.read(examProvider)),
      true,
    );
  });

  test('allocation becomes outdated when an exam is removed', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(allocationProvider.notifier).run();
    final run = c.read(allocationProvider)!;

    c.read(examProvider.notifier).remove('e1');
    expect(
      run.isOutdatedFor(c.read(staffProvider), c.read(examProvider)),
      true,
    );
  });

  test('run refuses when there are no exams', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(examProvider.notifier).remove('e1');
    c.read(examProvider.notifier).remove('e2');

    final error = c.read(allocationProvider.notifier).run();
    expect(error, 'Add exam sessions first');
    expect(c.read(allocationProvider), isNull);
  });

  test('run refuses when there are no staff', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(staffProvider.notifier).remove('s1');
    c.read(staffProvider.notifier).remove('s2');

    final error = c.read(allocationProvider.notifier).run();
    expect(error, 'Add staff members first');
    expect(c.read(allocationProvider), isNull);
  });
}