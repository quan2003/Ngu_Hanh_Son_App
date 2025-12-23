/// User Entity
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final bool isBlocked;
  final bool isDeleted;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
    this.isBlocked = false,
    this.isDeleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Không rõ',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isBlocked': isBlocked,
      'isDeleted': isDeleted,
    };
  }
}
