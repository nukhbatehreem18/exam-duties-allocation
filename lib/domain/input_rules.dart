import '../models/availability_slot.dart';
import '../models/exam_session.dart';
import '../models/staff.dart';

/// One duty is one exam session. Sessions last between these limits.
const int minSessionMinutes = 30;
const int maxSessionMinutes = 480; // 8 hours

/// Upper limit for the "max duties" setting of a staff member.
const int maxAllowedDuties = 20;

/// Returns an error message, or null when the value is valid.

String? validateEmailFormat(String? value) {
  final v = (value ?? '').trim();
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  return ok ? null : 'Enter a valid email address';
}

/// True if another staff member (not [exceptId]) already uses this email.
bool isEmailTaken(String email, List<Staff> staff, {String? exceptId}) {
  final e = email.trim().toLowerCase();
  return staff.any((s) => s.id != exceptId && s.email.trim().toLowerCase() == e);
}

/// The two limits must agree with each other, because every duty lasts
/// between [minSessionMinutes] and [maxSessionMinutes].
String? validateDutyLimits({required int maxDuties, required int maxMinutes}) {
  if (maxMinutes < maxDuties * minSessionMinutes) {
    return 'Max duty hours is too low for $maxDuties duties '
        '(each duty lasts at least $minSessionMinutes minutes)';
  }
  if (maxMinutes > maxDuties * maxSessionMinutes) {
    return 'Max duty hours is too high for $maxDuties duties '
        '(each duty lasts at most ${maxSessionMinutes ~/ 60} hours)';
  }
  return null;
}

String? validateNotInPast(DateTime start, DateTime now) {
  return start.isBefore(now) ? 'Start time cannot be in the past' : null;
}

/// Checks an exam's start and end. Pass checkPast: false when an existing
/// exam is edited without changing its time.
String? validateExamTimes({
  required DateTime start,
  required DateTime end,
  required DateTime now,
  bool checkPast = true,
}) {
  if (!end.isAfter(start)) return 'End time must be after start time';
  final minutes = end.difference(start).inMinutes;
  if (minutes < minSessionMinutes) {
    return 'An exam must last at least $minSessionMinutes minutes';
  }
  if (minutes > maxSessionMinutes) {
    return 'An exam cannot be longer than ${maxSessionMinutes ~/ 60} hours';
  }
  if (checkPast) return validateNotInPast(start, now);
  return null;
}

/// A room cannot host two exams at the same time (half-open intervals).
String? validateRoomClash({
  required ExamSession candidate,
  required List<ExamSession> existing,
}) {
  final room = candidate.room.trim().toLowerCase();
  for (final e in existing) {
    if (e.id == candidate.id) continue;
    if (e.room.trim().toLowerCase() == room &&
        e.interval.overlaps(candidate.interval)) {
      return 'Room "${candidate.room.trim()}" is already booked for '
          '"${e.course}" at this time';
    }
  }
  return null;
}

/// Checks a new availability slot of one staff member.
String? validateSlot({
  required AvailabilitySlot candidate,
  required List<AvailabilitySlot> existing,
  required DateTime now,
}) {
  if (!candidate.end.isAfter(candidate.start)) {
    return 'End time must be after start time';
  }
  final past = validateNotInPast(candidate.start, now);
  if (past != null) return past;
  for (final s in existing) {
    if (s.interval.overlaps(candidate.interval)) {
      return 'This slot overlaps an existing availability slot';
    }
  }
  return null;
}