import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/coordinator_home.dart';
import '../features/auth/staff_home.dart';
import '../features/staff/staff_list_screen.dart';
import '../features/staff/staff_form_screen.dart';
import '../features/staff/availability_screen.dart';
import '../features/exams/exam_list_screen.dart';
import '../features/exams/exam_form_screen.dart';
import '../models/user_role.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Notify the router to re-check whenever the user logs in or out.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final goingToLogin = state.matchedLocation == '/login';

      // 1) Not logged in -> go to the login screen
      if (user == null) {
        return goingToLogin ? null : '/login';
      }

      // 2) Logged in but on the login screen -> go to own home
      final home =
          user.role == UserRole.coordinator ? '/coordinator' : '/staff';
      if (goingToLogin) return home;

      // 3) Staff users must not open any coordinator page
      if (state.matchedLocation.startsWith('/coordinator') &&
          user.role != UserRole.coordinator) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/coordinator',
        builder: (_, __) => const CoordinatorHome(),
        routes: [
          GoRoute(
            path: 'staff',
            builder: (_, __) => const StaffListScreen(),
          ),
          GoRoute(
            path: 'staff/new',
            builder: (_, __) => const StaffFormScreen(),
          ),
          GoRoute(
            path: 'staff/:id/edit',
            builder: (_, state) =>
                StaffFormScreen(staffId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'staff/:id/availability',
            builder: (_, state) =>
                AvailabilityScreen(staffId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'exams',
            builder: (_, __) => const ExamListScreen(),
          ),
          GoRoute(
            path: 'exams/new',
            builder: (_, __) => const ExamFormScreen(),
          ),
          GoRoute(
            path: 'exams/:id/edit',
            builder: (_, state) =>
                ExamFormScreen(examId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(path: '/staff', builder: (_, __) => const StaffHome()),
    ],
  );
});