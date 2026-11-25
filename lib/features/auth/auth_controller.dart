import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';

/// Abhi ke liye fake users. Baad mein Firebase se badal denge.
const _fakeUsers = {
  'coordinator@bahria.edu.pk': AppUser(
    id: 'u1',
    name: 'Coordinator',
    role: UserRole.coordinator,
  ),
  'staff@bahria.edu.pk': AppUser(
    id: 'u2',
    name: 'Ali (Staff)',
    role: UserRole.staff,
  ),
};

const _fakePassword = '123456';

class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() => null; // shuru mein koi login nahi

  /// Sahi email/password ho to true, warna false.
  bool login(String email, String password) {
    final user = _fakeUsers[email.trim().toLowerCase()];
    if (user != null && password == _fakePassword) {
      state = user;
      return true;
    }
    return false;
  }

  void logout() => state = null;
}

final authProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);