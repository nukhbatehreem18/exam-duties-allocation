import 'user_role.dart';

/// Login hone ke baad app yaad rakhti hai ke kaun login hai.
class AppUser {
  final String id;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
  });
}