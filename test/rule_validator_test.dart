import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/domain/rule_validator.dart';
import 'package:exam_duties_allocation/models/availability_slot.dart';
import 'package:exam_duties_allocation/models/duty.dart';
import 'package:exam_duties_allocation/models/exam_session.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  ExamSession exam(String id, int sh, int eh) => ExamSession(
        id: id,
        course: 'Course $id',
        room: 'R-$id',
        start: DateTime(2026, 12, 1, sh, 0),
        end: DateTime(2026, 12, 1, eh, 0),
        requiredInvigilators: 2,
      );

  final a = exam('a', 9, 11); // 120 min
  final b = exam('b', 11, 13); // 120 min, back-to-back with a
  final c = exam('c', 10, 12); // overlaps a and b
  final d = exam('d', 13, 15); // 120 min

  final validator = RuleValidator([a, b, c, d]);

  Staff makeStaff({
    String id = 's1',
    int maxDuties = 3,
    int maxMinutes = 600,
    int availFrom = 8,
    int availTo = 16,
  }) =>
      Staff(
        id: id,
        name: 'Staff $id',
        email: '$id@bahria.edu.pk',
        maxDuties: maxDuties,
        maxMinutes: maxMinutes,
        availability: [
          AvailabilitySlot(
            start: DateTime(2026, 12, 1, availFrom, 0),
            end: DateTime(2026, 12, 1, availTo, 0),
          ),
        ],
      );

  test('allows a valid assignment', () {
    final r = validator.canAssign(staff: makeStaff(), session: a, duties: []);
    expect(r.allowed, true);
  });

  test('blocks the same person twice on the same exam', () {
    final r = validator.canAssign(
      staff: makeStaff(),
      session: a,
      duties: const [Duty(staffId: 's1', examId: 'a')],
    );
    expect(r.reason, BlockReason.alreadyAssigned);
  });

  test('blocks an exam that already has all required invigilators', () {
    final r = validator.canAssign(
      staff: makeStaff(),
      session: a,
      duties: const [
        Duty(staffId: 's2', examId: 'a'),
        Duty(staffId: 's3', examId: 'a'),
      ],
    );
    expect(r.reason, BlockReason.sessionFull);
  });

  test('blocks when the staff member is not available', () {
    final r = validator.canAssign(
      staff: makeStaff(availFrom: 12, availTo: 16),
      session: a,
      duties: [],
    );
    expect(r.reason, BlockReason.unavailable);
  });

  test('blocks a staff member with no availability at all', () {
    const noSlots = Staff(
      id: 's1',
      name: 'No slots',
      email: 'n@bahria.edu.pk',
      maxDuties: 3,
      maxMinutes: 600,
    );
    final r = validator.canAssign(staff: noSlots, session: a, duties: []);
    expect(r.reason, BlockReason.unavailable);
  });

  test('blocks an overlapping duty', () {
    final r = validator.canAssign(
      staff: makeStaff(),
      session: c,
      duties: const [Duty(staffId: 's1', examId: 'a')],
    );
    expect(r.reason, BlockReason.timeClash);
  });

  test('allows back-to-back duties (half-open)', () {
    final r = validator.canAssign(
      staff: makeStaff(),
      session: b,
      duties: const [Duty(staffId: 's1', examId: 'a')],
    );
    expect(r.allowed, true);
  });

  test('blocks when max duties would be exceeded', () {
    final r = validator.canAssign(
      staff: makeStaff(maxDuties: 2, maxMinutes: 600),
      session: d,
      duties: const [
        Duty(staffId: 's1', examId: 'a'),
        Duty(staffId: 's1', examId: 'b'),
      ],
    );
    expect(r.reason, BlockReason.maxDuties);
  });

  test('blocks when max minutes would be exceeded', () {
    // a (120) + b (120) = 240 already; d adds 120 -> 360 > 300.
    final r = validator.canAssign(
      staff: makeStaff(maxDuties: 3, maxMinutes: 300),
      session: d,
      duties: const [
        Duty(staffId: 's1', examId: 'a'),
        Duty(staffId: 's1', examId: 'b'),
      ],
    );
    expect(r.reason, BlockReason.maxMinutes);
  });

  test('allows exactly the minutes limit (inclusive)', () {
    // a (120) + d (120) = 240 <= 240.
    final r = validator.canAssign(
      staff: makeStaff(maxDuties: 3, maxMinutes: 240),
      session: d,
      duties: const [Duty(staffId: 's1', examId: 'a')],
    );
    expect(r.allowed, true);
  });

  test("other staff members' duties do not count against this person", () {
    final r = validator.canAssign(
      staff: makeStaff(maxDuties: 1, maxMinutes: 300),
      session: a,
      duties: const [Duty(staffId: 's2', examId: 'b')],
    );
    expect(r.allowed, true);
  });

  test('a replacement follows the same rules (remove old, then check)', () {
    // s1 is on exam a; replacing s1 with s2 means removing s1's duty first.
    const before = [Duty(staffId: 's1', examId: 'a')];
    final after = before.where((x) => x.staffId != 's1').toList();

    final ok = validator.canAssign(
        staff: makeStaff(id: 's2'), session: a, duties: after);
    expect(ok.allowed, true);

    // s2 is unavailable, so the replacement must be refused.
    final bad = validator.canAssign(
        staff: makeStaff(id: 's2', availFrom: 12), session: a, duties: after);
    expect(bad.reason, BlockReason.unavailable);
  });
}