import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/time_utils.dart';
import 'exam_controller.dart';

class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Copy the list and sort it by start time (the original is not changed).
    final exams = [...ref.watch(examProvider)]
      ..sort((a, b) => a.start.compareTo(b.start));
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Sessions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coordinator/exams/new'),
        child: const Icon(Icons.add),
      ),
      body: exams.isEmpty
          ? const Center(child: Text('No exam sessions yet'))
          : ListView.builder(
              itemCount: exams.length,
              itemBuilder: (context, i) {
                final e = exams[i];
                return ListTile(
                  title: Text(e.course),
                  subtitle: Text(
                    '${e.room} | ${dateFmt.format(e.start)}\n'
                    '${timeFmt.format(e.start)} - ${timeFmt.format(e.end)} '
                    '(${formatMinutes(e.durationMinutes)}) | '
                    '${e.requiredInvigilators} invigilator(s)',
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/coordinator/exams/${e.id}/edit'),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(examProvider.notifier).remove(e.id),
                  ),
                );
              },
            ),
    );
  }
}