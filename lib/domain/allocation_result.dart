import '../models/duty.dart';
import 'rule_validator.dart';

/// An invigilator slot that could not be filled (FR-08).
class Vacancy {
  final String examId;

  /// Which slot of the exam this is (1, 2, 3 ...).
  final int slotNumber;

  /// How many staff members were blocked, grouped by the blocking rule.
  final Map<BlockReason, int> blockedBy;

  const Vacancy({
    required this.examId,
    required this.slotNumber,
    required this.blockedBy,
  });

  /// A short readable text, for example "Not available: 3, Time clash: 1".
  String get summary {
    if (blockedBy.isEmpty) return 'No staff members exist';
    return blockedBy.entries
        .map((e) => '${blockReasonLabel(e.key)}: ${e.value}')
        .join(', ');
  }
}

/// The output of the allocation engine.
class AllocationResult {
  final List<Duty> duties;
  final List<Vacancy> vacancies;

  const AllocationResult({required this.duties, required this.vacancies});
}

/// Human-readable name of a blocking rule.
String blockReasonLabel(BlockReason reason) {
  switch (reason) {
    case BlockReason.alreadyAssigned:
      return 'Already on this exam';
    case BlockReason.sessionFull:
      return 'Exam already full';
    case BlockReason.unavailable:
      return 'Not available';
    case BlockReason.timeClash:
      return 'Time clash';
    case BlockReason.maxDuties:
      return 'Max duties reached';
    case BlockReason.maxMinutes:
      return 'Max duty hours reached';
  }
}