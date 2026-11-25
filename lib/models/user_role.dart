/// App mein sirf do tarah ke log hain.
enum UserRole {
  coordinator, // allocation karta hai, sab kuch dekh sakta hai
  staff,       // sirf apni duties dekhta hai
}

/// Text se role banata hai (database se parhte waqt kaam aata hai).
UserRole roleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.staff,
  );
}