import 'availability_slot.dart';
import '../core/time_utils.dart';

class Staff {
  final String id;
  final String name;
  final String email;
  final int maxDuties;          // zyada se zyada kitni duties
  final int maxMinutes;         // zyada se zyada kul minutes (integer)
  final List<AvailabilitySlot> availability;

  const Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.maxDuties,
    required this.maxMinutes,
    this.availability = const [],
  });

  /// Kya staff is exam ke poore waqt mein available hai?
  bool isAvailableFor(TimeInterval exam) {
    return availability.any((slot) => slot.covers(exam));
  }
}