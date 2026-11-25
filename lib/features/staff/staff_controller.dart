import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/staff.dart';
import '../../models/availability_slot.dart';

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

  void addSlot(String staffId, AvailabilitySlot slot) {
    state = [
      for (final s in state)
        if (s.id == staffId)
          Staff(
            id: s.id,
            name: s.name,
            email: s.email,
            maxDuties: s.maxDuties,
            maxMinutes: s.maxMinutes,
            availability: [...s.availability, slot],
          )
        else
          s,
    ];
  }

  void removeSlot(String staffId, int index) {
    state = [
      for (final s in state)
        if (s.id == staffId)
          Staff(
            id: s.id,
            name: s.name,
            email: s.email,
            maxDuties: s.maxDuties,
            maxMinutes: s.maxMinutes,
            availability: [
              for (var i = 0; i < s.availability.length; i++)
                if (i != index) s.availability[i],
            ],
          )
        else
          s,
    ];
  }
}

final staffProvider =
    NotifierProvider<StaffController, List<Staff>>(StaffController.new);