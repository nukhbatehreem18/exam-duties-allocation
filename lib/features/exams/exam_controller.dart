import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exam_session.dart';

class ExamController extends Notifier<List<ExamSession>> {
  @override
  List<ExamSession> build() => [
        ExamSession(
          id: 'e1',
          course: 'SEN-311 Software Construction',
          room: 'Room 101',
          start: DateTime(2026, 12, 14, 9, 0),
          end: DateTime(2026, 12, 14, 11, 0),
          requiredInvigilators: 2,
        ),
        ExamSession(
          id: 'e2',
          course: 'CSC-210 Data Structures',
          room: 'Room 102',
          start: DateTime(2026, 12, 14, 11, 0),
          end: DateTime(2026, 12, 14, 13, 0),
          requiredInvigilators: 1,
        ),
      ];

  void add(ExamSession exam) => state = [...state, exam];

  void update(ExamSession exam) => state = [
        for (final e in state)
          if (e.id == exam.id) exam else e,
      ];

  void remove(String id) => state = state.where((e) => e.id != id).toList();
}

final examProvider =
    NotifierProvider<ExamController, List<ExamSession>>(ExamController.new);