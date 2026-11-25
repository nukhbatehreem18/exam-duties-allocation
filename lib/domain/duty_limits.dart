import '../models/staff.dart';

/// Result of a limit check. If [allowed] is false, [reason] says why.
class LimitCheck {
  final bool allowed;
  final String? reason;

  const LimitCheck.ok()
      : allowed = true,
        reason = null;

  const LimitCheck.blocked(this.reason) : allowed = false;
}

/// Checks a staff member's duty-count and duty-minutes limits (FR-03).
///
/// [currentDuties] = duties already assigned to this staff member.
/// [currentMinutes] = total minutes already assigned (integer).
/// [newDutyMinutes] = duration_minutes of the duty we want to add.
LimitCheck checkLimits({
  required Staff staff,
  required int currentDuties,
  required int currentMinutes,
  required int newDutyMinutes,
}) {
  if (currentDuties + 1 > staff.maxDuties) {
    return const LimitCheck.blocked('Maximum number of duties reached');
  }
  if (currentMinutes + newDutyMinutes > staff.maxMinutes) {
    return const LimitCheck.blocked('Maximum duty minutes exceeded');
  }
  return const LimitCheck.ok();
}