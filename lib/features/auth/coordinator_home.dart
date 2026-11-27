import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class CoordinatorHome extends ConsumerWidget {
  const CoordinatorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, ${user?.name ?? ''}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/coordinator/staff'),
              icon: const Icon(Icons.people),
              label: const Text('Manage Staff'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/coordinator/exams'),
              icon: const Icon(Icons.event_note),
              label: const Text('Manage Exam Sessions'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/coordinator/allocation'),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Allocation'),
            ),
          ],
        ),
      ),
    );
  }
}