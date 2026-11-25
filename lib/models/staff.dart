import 'availability_slot.dart';
import '../core/time_utils.dart';

class Staff {
  final String id;
  final String name;
  final String email;
  final int maxDuties; // maximum number of duties
  final int maxMinutes; // maximum total duty minutes (integer)
  final List<AvailabilitySlot> availability;

  const Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.maxDuties,
    required this.maxMinutes,
    this.availability = const [],
  });

  /// True if the staff member is available for the whole exam time.
  bool isAvailableFor(TimeInterval exam) {
    return availability.any((slot) => slot.covers(exam));
  }
}