class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role; // student | teacher | admin
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}
