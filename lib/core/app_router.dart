import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/coordinator_home.dart';
import '../features/auth/staff_home.dart';
import '../models/user_role.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Jab bhi login/logout ho, router ko batao ke dobara check kare.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final goingToLogin = state.matchedLocation == '/login';

      // 1) Login nahi hai -> login screen
      if (user == null) {
        return goingToLogin ? null : '/login';
      }

      // 2) Login hai magar login screen par -> apne home par bhejo
      final home =
          user.role == UserRole.coordinator ? '/coordinator' : '/staff';
      if (goingToLogin) return home;

      // 3) Staff coordinator ke page par jaye to wapas bhejo
      if (state.matchedLocation == '/coordinator' &&
          user.role != UserRole.coordinator) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/coordinator', builder: (_, __) => const CoordinatorHome()),
      GoRoute(path: '/staff', builder: (_, __) => const StaffHome()),
    ],
  );
});