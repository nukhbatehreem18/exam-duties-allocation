import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/time_utils.dart';
import 'staff_controller.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffList = ref.watch(staffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/coordinator/staff/new'),
        child: const Icon(Icons.add),
      ),
      body: staffList.isEmpty
          ? const Center(child: Text('No staff added yet'))
          : ListView.builder(
              itemCount: staffList.length,
              itemBuilder: (context, i) {
                final s = staffList[i];
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    '${s.email}\n'
                    'Max ${s.maxDuties} duties, ${formatMinutes(s.maxMinutes)}',
                  ),
                  isThreeLine: true,
                  onTap: () =>
                      context.push('/coordinator/staff/${s.id}/edit'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(staffProvider.notifier).remove(s.id),
                  ),
                );
              },
            ),
    );
  }
}