import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/features/exams/exam_controller.dart';
import 'package:exam_duties_allocation/models/exam_session.dart';

void main() {
  final morning = ExamSession(
    id: 'a',
    course: 'Course A',
    room: 'R1',
    start: DateTime(2026, 12, 1, 9, 0),
    end: DateTime(2026, 12, 1, 11, 30),
    requiredInvigilators: 2,
  );

  test('durationMinutes is calculated as integer minutes', () {
    expect(morning.durationMinutes, 150);
  });

  test('back-to-back sessions do not overlap (half-open)', () {
    final next = ExamSession(
      id: 'b',
      course: 'Course B',
      room: 'R2',
      start: DateTime(2026, 12, 1, 11, 30),
      end: DateTime(2026, 12, 1, 13, 0),
      requiredInvigilators: 1,
    );
    expect(morning.interval.overlaps(next.interval), false);
  });

  test('overlapping sessions are detected', () {
    final clash = ExamSession(
      id: 'c',
      course: 'Course C',
      room: 'R3',
      start: DateTime(2026, 12, 1, 10, 0),
      end: DateTime(2026, 12, 1, 12, 0),
      requiredInvigilators: 1,
    );
    expect(morning.interval.overlaps(clash.interval), true);
  });

  test('exam controller add, update and remove work', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(examProvider.notifier);
    final initial = container.read(examProvider).length;

    controller.add(morning);
    expect(container.read(examProvider).length, initial + 1);

    controller.update(ExamSession(
      id: 'a',
      course: 'Renamed',
      room: 'R1',
      start: morning.start,
      end: morning.end,
      requiredInvigilators: 2,
    ));
    expect(
      container.read(examProvider).firstWhere((e) => e.id == 'a').course,
      'Renamed',
    );

    controller.remove('a');
    expect(container.read(examProvider).length, initial);
  });
}