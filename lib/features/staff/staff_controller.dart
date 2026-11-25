import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/staff.dart';

class StaffController extends Notifier<List<Staff>> {
  @override
  List<Staff> build() => [
        Staff(
          id: 's1',
          name: 'Ali Khan',
          email: 'ali@bahria.edu.pk',
          maxDuties: 3,
          maxMinutes: 360,
        ),
        Staff(
          id: 's2',
          name: 'Sara Ahmed',
          email: 'sara@bahria.edu.pk',
          maxDuties: 4,
          maxMinutes: 480,
        ),
      ];

  void add(Staff staff) => state = [...state, staff];

  void update(Staff staff) => state = [
        for (final s in state)
          if (s.id == staff.id) staff else s,
      ];

  void remove(String id) => state = state.where((s) => s.id != id).toList();
}

final staffProvider =
    NotifierProvider<StaffController, List<Staff>>(StaffController.new);