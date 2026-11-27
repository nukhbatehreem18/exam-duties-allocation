import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/domain/allocation_engine.dart';
import 'package:exam_duties_allocation/domain/rule_validator.dart';
import 'package:exam_duties_allocation/models/availability_slot.dart';
import 'package:exam_duties_allocation/models/exam_session.dart';
import 'package:exam_duties_allocation/models/staff.dart';
import 'package:exam_duties_allocation/domain/allocation_result.dart';

void main() {
  const engine = AllocationEngine();

  ExamSession exam(String id, int sh, int eh, {int required = 1}) =>
      ExamSession(
        id: id,
        course: 'Course $id',
        room: 'R-$id',
        start: DateTime(2026, 12, 1, sh, 0),
        end: DateTime(2026, 12, 1, eh, 0),
        requiredInvigilators: required,
      );

  AvailabilitySlot slot(int sh, int eh) => AvailabilitySlot(
        start: DateTime(2026, 12, 1, sh, 0),
        end: DateTime(2026, 12, 1, eh, 0),
      );

  Staff person(
    String id, {
    List<AvailabilitySlot>? slots,
    int maxDuties = 5,
    int maxMinutes = 600,
  }) =>
      Staff(
        id: id,
        name: 'Staff $id',
        email: '$id@bahria.edu.pk',
        maxDuties: maxDuties,
        maxMinutes: maxMinutes,
        availability: slots ?? [slot(8, 16)],
      );

  List<String> pairs(AllocationResult r) =>
      r.duties.map((d) => '${d.staffId}:${d.examId}').toList();

  test('fills every slot when enough staff are eligible', () {
    final r = engine.allocate(
      staff: [person('a'), person('b')],
      sessions: [exam('x', 9, 11, required: 2)],
    );
    expect(r.duties.length, 2);
    expect(r.vacancies, isEmpty);
    expect(r.duties.map((d) => d.staffId).toSet(), {'a', 'b'});
  });

  test('scarcity: the hardest session is filled first', () {
    // "e" (09-11) can be done by a or b. "h" (13-15) only by a.
    // Each person can do only 1 duty. Filling by time would give a to "e"
    // and leave "h" empty. Scarcity order gives a to "h" and b to "e".
    final a = person('a', maxDuties: 1, maxMinutes: 480);
    final b = person('b', maxDuties: 1, maxMinutes: 480, slots: [slot(8, 12)]);
    final r = engine.allocate(
      staff: [a, b],
      sessions: [exam('e', 9, 11), exam('h', 13, 15)],
    );
    expect(pairs(r), containsAll(['a:h', 'b:e']));
    expect(r.vacancies, isEmpty);
  });

  test('tie-break 1: lowest total duty minutes is chosen', () {
    // Both sessions have 2 eligible staff. a takes s1 (fixed order),
    // so s2 must go to b, who has fewer minutes.
    final r = engine.allocate(
      staff: [person('a'), person('b')],
      sessions: [exam('s1', 9, 11), exam('s2', 12, 14)],
    );
    expect(pairs(r), ['a:s1', 'b:s2']);
  });

  test('tie-break 2: equal minutes -> lowest duty count is chosen', () {
    // a: s1 (120 min, 1 duty). b: s2 + s3 (60 + 60 = 120 min, 2 duties).
    // For s4 both have 120 minutes, so the one with fewer duties (a) wins.
    final a = person('a', slots: [slot(11, 13), slot(14, 15)]);
    final b = person('b', slots: [slot(9, 11), slot(14, 15)]);
    final r = engine.allocate(
      staff: [a, b],
      sessions: [
        exam('s1', 11, 13),
        exam('s2', 9, 10),
        exam('s3', 10, 11),
        exam('s4', 14, 15),
      ],
    );
    expect(r.vacancies, isEmpty);
    final s4 = r.duties.firstWhere((d) => d.examId == 's4');
    expect(s4.staffId, 'a');
  });

  test('tie-break 3: fixed order (staff id) when everything is equal', () {
    final r = engine.allocate(
      staff: [person('b'), person('a')], // input order is not sorted
      sessions: [exam('x', 9, 11)],
    );
    expect(pairs(r), ['a:x']);
  });

  test('back-to-back sessions can go to the same person (half-open)', () {
    final r = engine.allocate(
      staff: [person('a', maxDuties: 2)],
      sessions: [exam('s1', 9, 11), exam('s2', 11, 13)],
    );
    expect(r.duties.length, 2);
    expect(r.vacancies, isEmpty);
  });

  test('overlapping sessions are never given to the same person', () {
    final r = engine.allocate(
      staff: [person('a')],
      sessions: [exam('s1', 9, 11), exam('s2', 10, 12)],
    );
    expect(r.duties.length, 1);
    expect(r.vacancies.length, 1);
    expect(r.vacancies.first.blockedBy[BlockReason.timeClash], 1);
  });

  test('vacancy lists the blocking constraints', () {
    // Exam needs 2. a is available, b has no availability at all.
    final r = engine.allocate(
      staff: [person('a'), person('b', slots: [])],
      sessions: [exam('x', 9, 11, required: 2)],
    );
    expect(r.duties.length, 1);
    expect(r.vacancies.length, 1);

    final v = r.vacancies.first;
    expect(v.examId, 'x');
    expect(v.slotNumber, 2);
    expect(v.blockedBy[BlockReason.alreadyAssigned], 1); // a
    expect(v.blockedBy[BlockReason.unavailable], 1); // b
    expect(v.summary, isNotEmpty);
  });

  test('with no staff every slot is a vacancy', () {
    final r = engine.allocate(
      staff: const [],
      sessions: [exam('x', 9, 11, required: 2)],
    );
    expect(r.duties, isEmpty);
    expect(r.vacancies.length, 2);
    expect(r.vacancies.first.summary, 'No staff members exist');
  });

  test('max minutes limit is respected', () {
    // a can work only 150 minutes, so cannot take two 120-minute exams.
    final r = engine.allocate(
      staff: [person('a', maxDuties: 5, maxMinutes: 150)],
      sessions: [exam('s1', 9, 11), exam('s2', 12, 14)],
    );
    expect(r.duties.length, 1);
    expect(r.vacancies.first.blockedBy[BlockReason.maxMinutes], 1);
  });

  test('result is repeatable: the same input gives the same output', () {
    final staff = [person('a'), person('b'), person('c')];
    final sessions = [
      exam('x', 9, 11, required: 2),
      exam('y', 10, 12, required: 2),
      exam('z', 12, 14),
    ];
    final first = engine.allocate(staff: staff, sessions: sessions);
    final second = engine.allocate(staff: staff, sessions: sessions);
    expect(pairs(first), pairs(second));
  });

  test('a generated roster never breaks any rule', () {
    final staff = [
      person('a', maxDuties: 2, maxMinutes: 300),
      person('b', maxDuties: 2, maxMinutes: 300),
      person('c', maxDuties: 2, maxMinutes: 300, slots: [slot(8, 12)]),
    ];
    final sessions = [
      exam('x', 9, 11, required: 2),
      exam('y', 10, 12, required: 2),
      exam('z', 11, 13),
      exam('w', 14, 15, required: 2),
    ];
    final r = engine.allocate(staff: staff, sessions: sessions);
    final byId = {for (final s in sessions) s.id: s};

    for (final s in staff) {
      final mine = r.duties.where((d) => d.staffId == s.id).toList();

      // Duty-count and duty-minutes limits.
      expect(mine.length <= s.maxDuties, true);
      final total = mine.fold<int>(
          0, (sum, d) => sum + byId[d.examId]!.durationMinutes);
      expect(total <= s.maxMinutes, true);

      // Available for every duty, and no two duties overlap.
      for (final d in mine) {
        expect(s.isAvailableFor(byId[d.examId]!.interval), true);
      }
      for (var i = 0; i < mine.length; i++) {
        for (var j = i + 1; j < mine.length; j++) {
          final a = byId[mine[i].examId]!;
          final b = byId[mine[j].examId]!;
          expect(a.interval.overlaps(b.interval), false);
        }
      }
    }

    // For every session: duties + vacancies = required invigilators.
    for (final e in sessions) {
      final filled = r.duties.where((d) => d.examId == e.id).length;
      final empty = r.vacancies.where((v) => v.examId == e.id).length;
      expect(filled + empty, e.requiredInvigilators);
    }
  });
}