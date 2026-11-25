import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/availability_slot.dart';
import 'staff_controller.dart';

class AvailabilityScreen extends ConsumerWidget {
  final String staffId;
  const AvailabilityScreen({super.key, required this.staffId});

  Future<void> _addSlot(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );
    if (date == null || !context.mounted) return;

    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Start time',
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 0),
      helpText: 'End time',
    );
    if (end == null || !context.mounted) return;

    final startDt =
        DateTime(date.year, date.month, date.day, start.hour, start.minute);
    final endDt =
        DateTime(date.year, date.month, date.day, end.hour, end.minute);

    if (!endDt.isAfter(startDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    ref
        .read(staffProvider.notifier)
        .addSlot(staffId, AvailabilitySlot(start: startDt, end: endDt));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProvider).firstWhere((s) => s.id == staffId);
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Availability: ${staff.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSlot(context, ref),
        child: const Icon(Icons.add),
      ),
      body: staff.availability.isEmpty
          ? const Center(child: Text('No availability slots yet'))
          : ListView.builder(
              itemCount: staff.availability.length,
              itemBuilder: (context, i) {
                final slot = staff.availability[i];
                return ListTile(
                  title: Text(dateFmt.format(slot.start)),
                  subtitle: Text(
                    '${timeFmt.format(slot.start)} - ${timeFmt.format(slot.end)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(staffProvider.notifier)
                        .removeSlot(staffId, i),
                  ),
                );
              },
            ),
    );
  }
}