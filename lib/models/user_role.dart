/// The two roles in the app.
enum UserRole {
  coordinator, // runs allocation and can see everything
  staff, // can only see their own duties
}

/// Converts text (for example from a database) to a role.
/// Unknown text falls back to the safest role: staff.
UserRole roleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.staff,
  );
}