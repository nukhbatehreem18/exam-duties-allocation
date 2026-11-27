import '../models/duty.dart';
import '../models/exam_session.dart';
import '../models/staff.dart';
import 'duty_limits.dart';

/// Why an assignment was blocked. The vacancy report (FR-08) uses this.
enum BlockReason {
  alreadyAssigned,
  sessionFull,
  unavailable,
  timeClash,
  maxDuties,
  maxMinutes,
}

/// Result of a check. If [allowed] is false, [reason] and [message] explain why.
class AssignmentCheck {
  final bool allowed;
  final BlockReason? reason;
  final String? message;

  const AssignmentCheck.ok()
      : allowed = true,
        reason = null,
        message = null;

  const AssignmentCheck.blocked(BlockReason this.reason, String this.message)
      : allowed = false;
}

/// The single place where all assignment rules are checked.
/// Used by the allocation engine and by manual replacement (same rules).
class RuleValidator {
  /// All exam sessions, so a duty's examId can be turned into a time.
  final List<ExamSession> sessions;

  const RuleValidator(this.sessions);

  /// Can [staff] be assigned to [session], given the [duties] made so far?
  AssignmentCheck canAssign({
    required Staff staff,
    required ExamSession session,
    required List<Duty> duties,
  }) {
    final byId = {for (final s in sessions) s.id: s};
    final mine = duties.where((d) => d.staffId == staff.id).toList();

    // 1) The same person cannot be assigned twice to the same exam.
    if (mine.any((d) => d.examId == session.id)) {
      return const AssignmentCheck.blocked(
        BlockReason.alreadyAssigned,
        'Already assigned to this exam',
      );
    }

    // 2) The exam must not already have all its required invigilators.
    final filled = duties.where((d) => d.examId == session.id).length;
    if (filled >= session.requiredInvigilators) {
      return const AssignmentCheck.blocked(
        BlockReason.sessionFull,
        'This exam already has all required invigilators',
      );
    }

    // 3) The staff member must be available for the whole exam.
    if (!staff.isAvailableFor(session.interval)) {
      return const AssignmentCheck.blocked(
        BlockReason.unavailable,
        'Not available during this exam',
      );
    }

    // 4) No overlap with the staff member's other duties (half-open).
    for (final d in mine) {
      final other = byId[d.examId];
      if (other != null && other.interval.overlaps(session.interval)) {
        return AssignmentCheck.blocked(
          BlockReason.timeClash,
          'Time clash with another duty (${other.course})',
        );
      }
    }

    // 5) Duty-count and total-minutes limits.
    final currentMinutes =
        mine.fold<int>(0, (sum, d) => sum + (byId[d.examId]?.durationMinutes ?? 0));
    final limit = checkLimits(
      staff: staff,
      currentDuties: mine.length,
      currentMinutes: currentMinutes,
      newDutyMinutes: session.durationMinutes,
    );
    if (!limit.allowed) {
      final reason = mine.length + 1 > staff.maxDuties
          ? BlockReason.maxDuties
          : BlockReason.maxMinutes;
      return AssignmentCheck.blocked(reason, limit.reason!);
    }

    return const AssignmentCheck.ok();
  }
}