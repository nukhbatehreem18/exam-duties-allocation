import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/time_utils.dart';
import '../../models/exam_session.dart';
import '../exams/exam_controller.dart';
import '../staff/staff_controller.dart';
import 'allocation_controller.dart';

class AllocationScreen extends ConsumerWidget {
  const AllocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(allocationProvider);
    final staffNow = ref.watch(staffProvider);
    final examsNow = ref.watch(examProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Allocation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () {
                  final error = ref.read(allocationProvider.notifier).run();
                  if (error != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                icon: const Icon(Icons.auto_fix_high),
                label: Text(
                    run == null ? 'Run allocation' : 'Run allocation again'),
              ),
              const SizedBox(height: 16),
              if (run == null)
                const Text(
                  'No allocation yet. Press the button to generate a draft '
                  'roster from the current staff and exam sessions.',
                )
              else
                ..._buildResult(
                  context,
                  run,
                  run.isOutdatedFor(staffNow, examsNow),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResult(
      BuildContext context, AllocationRun run, bool outdated) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');
    final result = run.result;
    final names = {for (final s in run.staff) s.id: s.name};
    final examById = {for (final e in run.exams) e.id: e};
    final exams = [...run.exams]..sort((a, b) => a.start.compareTo(b.start));
    final scheme = Theme.of(context).colorScheme;

    final widgets = <Widget>[];

    // Warning when staff or exams changed after the allocation.
    if (outdated) {
      widgets.add(Card(
        color: scheme.errorContainer,
        child: ListTile(
          leading: Icon(Icons.warning_amber, color: scheme.error),
          title: const Text(
            'Staff or exam data changed after this allocation. '
            'Run the allocation again.',
          ),
        ),
      ));
    }

    // Summary.
    widgets.add(Text(
      '${result.duties.length} duties assigned, '
      '${result.vacancies.length} vacancies '
      '(generated at ${timeFmt.format(run.createdAt)})',
      style: Theme.of(context).textTheme.titleMedium,
    ));
    widgets.add(const SizedBox(height: 4));
    widgets.add(Text(result.vacancies.isEmpty
        ? 'All invigilator slots are filled.'
        : 'Some slots could not be filled. See the reasons below.'));
    widgets.add(const SizedBox(height: 16));

    // Roster by exam.
    widgets.add(Text('Roster by exam',
        style: Theme.of(context).textTheme.titleMedium));
    for (final e in exams) {
      final assigned = result.duties.where((d) => d.examId == e.id).toList();
      final empty = result.vacancies.where((v) => v.examId == e.id).toList();
      widgets.add(Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(e.course),
              subtitle: Text(
                '${e.room} | ${dateFmt.format(e.start)} | '
                '${timeFmt.format(e.start)} - ${timeFmt.format(e.end)} | '
                '${assigned.length}/${e.requiredInvigilators} filled',
              ),
            ),
            for (final d in assigned)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person),
                title: Text(names[d.staffId] ?? d.staffId),
              ),
            for (final v in empty)
              ListTile(
                dense: true,
                leading: Icon(Icons.warning_amber, color: scheme.error),
                title: Text('Vacancy (slot ${v.slotNumber})'),
                subtitle: Text(v.summary),
              ),
          ],
        ),
      ));
    }

    // Workload per staff member.
    widgets.add(const SizedBox(height: 16));
    widgets.add(Text('Workload per staff member',
        style: Theme.of(context).textTheme.titleMedium));
    final staffSorted = [...run.staff]
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final s in staffSorted) {
      final mine = result.duties.where((d) => d.staffId == s.id).toList();
      final minutes = mine.fold<int>(
          0, (sum, d) => sum + (examById[d.examId]?.durationMinutes ?? 0));
      widgets.add(ListTile(
        title: Text(s.name),
        subtitle: Text(
          '${mine.length} duties, ${formatMinutes(minutes)} '
          '(limit: ${s.maxDuties} duties, ${formatMinutes(s.maxMinutes)})',
        ),
      ));
    }

    return widgets;
  }
}