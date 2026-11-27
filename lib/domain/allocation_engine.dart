import '../models/duty.dart';
import '../models/exam_session.dart';
import '../models/staff.dart';
import 'allocation_result.dart';
import 'rule_validator.dart';

/// Greedy, constraint-checked allocation (FR-06, FR-07, FR-08).
///
/// 1. Sessions with the fewest eligible staff are filled first (scarcity).
/// 2. For every invigilator slot, only staff who pass [RuleValidator] are
///    eligible.
/// 3. Among eligible staff, the one with the lowest total duty minutes is
///    chosen. Ties: lowest duty count, then lowest staff id (fixed order).
/// 4. If nobody is eligible, the slot becomes a [Vacancy] with its reasons.
class AllocationEngine {
  const AllocationEngine();

  AllocationResult allocate({
    required List<Staff> staff,
    required List<ExamSession> sessions,
  }) {
    final validator = RuleValidator(sessions);

    // Step 1: scarcity = how many staff could take this session on their own.
    final eligibleCount = <String, int>{};
    for (final session in sessions) {
      eligibleCount[session.id] = staff
          .where((s) => validator
              .canAssign(staff: s, session: session, duties: const [])
              .allowed)
          .length;
    }

    // Fewest eligible first. Ties: earlier start, then session id.
    final ordered = [...sessions]..sort((a, b) {
        final byScarcity = eligibleCount[a.id]!.compareTo(eligibleCount[b.id]!);
        if (byScarcity != 0) return byScarcity;
        final byStart = a.start.compareTo(b.start);
        if (byStart != 0) return byStart;
        return a.id.compareTo(b.id);
      });

    final duties = <Duty>[];
    final vacancies = <Vacancy>[];
    final minutes = {for (final s in staff) s.id: 0}; // total duty minutes
    final counts = {for (final s in staff) s.id: 0}; // number of duties

    for (final session in ordered) {
      for (var slot = 1; slot <= session.requiredInvigilators; slot++) {
        // Step 2: who is eligible for this slot, and who is blocked and why.
        final eligible = <Staff>[];
        final blocked = <BlockReason, int>{};
        for (final s in staff) {
          final check = validator.canAssign(
            staff: s,
            session: session,
            duties: duties,
          );
          if (check.allowed) {
            eligible.add(s);
          } else {
            blocked[check.reason!] = (blocked[check.reason!] ?? 0) + 1;
          }
        }

        // Step 4: nobody eligible -> vacancy.
        if (eligible.isEmpty) {
          vacancies.add(Vacancy(
            examId: session.id,
            slotNumber: slot,
            blockedBy: blocked,
          ));
          continue;
        }

        // Step 3: lowest minutes, then lowest count, then fixed order (id).
        eligible.sort((a, b) {
          final byMinutes = minutes[a.id]!.compareTo(minutes[b.id]!);
          if (byMinutes != 0) return byMinutes;
          final byCount = counts[a.id]!.compareTo(counts[b.id]!);
          if (byCount != 0) return byCount;
          return a.id.compareTo(b.id);
        });
        final chosen = eligible.first;

        duties.add(Duty(staffId: chosen.id, examId: session.id));
        minutes[chosen.id] = minutes[chosen.id]! + session.durationMinutes;
        counts[chosen.id] = counts[chosen.id]! + 1;
      }
    }

    return AllocationResult(duties: duties, vacancies: vacancies);
  }
}