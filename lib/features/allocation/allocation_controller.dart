import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/allocation_engine.dart';
import '../../domain/allocation_result.dart';
import '../../models/exam_session.dart';
import '../../models/staff.dart';
import '../exams/exam_controller.dart';
import '../staff/staff_controller.dart';

/// One allocation run, together with the data it was made from.
class AllocationRun {
  final AllocationResult result;
  final List<Staff> staff;
  final List<ExamSession> exams;
  final DateTime createdAt;

  const AllocationRun({
    required this.result,
    required this.staff,
    required this.exams,
    required this.createdAt,
  });

  /// True if staff or exams were changed after this run was made.
  bool isOutdatedFor(List<Staff> currentStaff, List<ExamSession> currentExams) {
    return !identical(currentStaff, staff) || !identical(currentExams, exams);
  }
}

class AllocationController extends Notifier<AllocationRun?> {
  @override
  AllocationRun? build() => null; // no allocation at the start

  /// Runs the allocation. Returns an error message, or null on success.
  String? run() {
    final staff = ref.read(staffProvider);
    final exams = ref.read(examProvider);

    if (exams.isEmpty) return 'Add exam sessions first';
    if (staff.isEmpty) return 'Add staff members first';

    final result =
        const AllocationEngine().allocate(staff: staff, sessions: exams);
    state = AllocationRun(
      result: result,
      staff: staff,
      exams: exams,
      createdAt: DateTime.now(),
    );
    return null;
  }
}

final allocationProvider =
    NotifierProvider<AllocationController, AllocationRun?>(
        AllocationController.new);