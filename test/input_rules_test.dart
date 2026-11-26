import 'package:flutter_test/flutter_test.dart';
import 'package:exam_duties_allocation/domain/input_rules.dart';
import 'package:exam_duties_allocation/models/availability_slot.dart';
import 'package:exam_duties_allocation/models/exam_session.dart';
import 'package:exam_duties_allocation/models/staff.dart';

void main() {
  // "Now" is 26 Nov 2026, 15:29.
  final now = DateTime(2026, 11, 26, 15, 29);

  group('email rules', () {
    test('accepts a valid email', () {
      expect(validateEmailFormat('ali@bahria.edu.pk'), isNull);
    });
    test('rejects invalid emails', () {
      expect(validateEmailFormat('abc'), isNotNull);
      expect(validateEmailFormat('abc@'), isNotNull);
      expect(validateEmailFormat('a b@c.com'), isNotNull);
      expect(validateEmailFormat(''), isNotNull);
    });
    test('detects a duplicate email, ignoring case and the same staff', () {
      const list = [
        Staff(
            id: 's1',
            name: 'Ali',
            email: 'ali@bahria.edu.pk',
            maxDuties: 3,
            maxMinutes: 360),
      ];
      expect(isEmailTaken('ALI@bahria.edu.pk ', list), true);
      expect(isEmailTaken('ali@bahria.edu.pk', list, exceptId: 's1'), false);
      expect(isEmailTaken('new@bahria.edu.pk', list), false);
    });
  });

  group('duty limits', () {
    test('3 duties and 6 hours is consistent', () {
      expect(validateDutyLimits(maxDuties: 3, maxMinutes: 360), isNull);
    });
    test('10 duties in 2 hours is impossible', () {
      expect(validateDutyLimits(maxDuties: 10, maxMinutes: 120), isNotNull);
    });
    test('1 duty with 100 hours is impossible', () {
      expect(validateDutyLimits(maxDuties: 1, maxMinutes: 6000), isNotNull);
    });
    test('boundaries are allowed', () {
      expect(validateDutyLimits(maxDuties: 2, maxMinutes: 60), isNull);
      expect(validateDutyLimits(maxDuties: 2, maxMinutes: 960), isNull);
    });
  });

  group('exam times', () {
    final day = DateTime(2026, 12, 1);
    DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);

    test('end before start is rejected (end 9:00, start 9:30)', () {
      expect(
        validateExamTimes(start: at(9, 30), end: at(9, 0), now: now),
        'End time must be after start time',
      );
    });
    test('end equal to start is rejected', () {
      expect(
        validateExamTimes(start: at(9, 0), end: at(9, 0), now: now),
        isNotNull,
      );
    });
    test('too short and too long exams are rejected', () {
      expect(validateExamTimes(start: at(9, 0), end: at(9, 20), now: now),
          isNotNull);
      expect(validateExamTimes(start: at(9, 0), end: at(18, 0), now: now),
          isNotNull);
    });
    test('a valid future exam is accepted', () {
      expect(validateExamTimes(start: at(9, 0), end: at(11, 0), now: now),
          isNull);
    });
    test('today 8:30 is in the past when it is already 15:29', () {
      final start = DateTime(2026, 11, 26, 8, 30);
      final end = DateTime(2026, 11, 26, 10, 30);
      expect(validateExamTimes(start: start, end: end, now: now),
          'Start time cannot be in the past');
    });
    test('past check can be skipped for unchanged existing exams', () {
      final start = DateTime(2026, 11, 26, 8, 30);
      final end = DateTime(2026, 11, 26, 10, 30);
      expect(
        validateExamTimes(start: start, end: end, now: now, checkPast: false),
        isNull,
      );
    });
    test('today 16:00 is accepted', () {
      final start = DateTime(2026, 11, 26, 16, 0);
      final end = DateTime(2026, 11, 26, 18, 0);
      expect(validateExamTimes(start: start, end: end, now: now), isNull);
    });
  });

  group('room clash', () {
    ExamSession exam(String id, String room, int sh, int eh) => ExamSession(
          id: id,
          course: 'Course $id',
          room: room,
          start: DateTime(2026, 12, 1, sh, 0),
          end: DateTime(2026, 12, 1, eh, 0),
          requiredInvigilators: 1,
        );

    final existing = [exam('a', 'Room 101', 9, 11)];

    test('same room and overlapping time is rejected', () {
      expect(
        validateRoomClash(
            candidate: exam('b', 'room 101 ', 10, 12), existing: existing),
        isNotNull,
      );
    });
    test('back-to-back in the same room is allowed (half-open)', () {
      expect(
        validateRoomClash(
            candidate: exam('b', 'Room 101', 11, 13), existing: existing),
        isNull,
      );
    });
    test('a different room is allowed', () {
      expect(
        validateRoomClash(
            candidate: exam('b', 'Room 102', 9, 11), existing: existing),
        isNull,
      );
    });
    test('an exam does not clash with itself when edited', () {
      expect(
        validateRoomClash(
            candidate: exam('a', 'Room 101', 9, 12), existing: existing),
        isNull,
      );
    });
  });

  group('availability slots', () {
    AvailabilitySlot slot(int sh, int eh) => AvailabilitySlot(
          start: DateTime(2026, 12, 1, sh, 0),
          end: DateTime(2026, 12, 1, eh, 0),
        );

    final existing = [slot(9, 12)];

    test('overlapping slot is rejected', () {
      expect(
          validateSlot(candidate: slot(11, 14), existing: existing, now: now),
          isNotNull);
    });
    test('touching slot is allowed (half-open)', () {
      expect(
          validateSlot(candidate: slot(12, 14), existing: existing, now: now),
          isNull);
    });
    test('slot in the past is rejected', () {
      final past = AvailabilitySlot(
        start: DateTime(2026, 11, 26, 8, 0),
        end: DateTime(2026, 11, 26, 10, 0),
      );
      expect(validateSlot(candidate: past, existing: const [], now: now),
          'Start time cannot be in the past');
    });
  });
}