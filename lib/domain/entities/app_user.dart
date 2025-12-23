enum UserRole {
  admin,
  user,
  moderator,
}

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;
  final bool?
      skipEmailVerification; // For phone login users who don't need email verification

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.role = UserRole.user,
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.skipEmailVerification,
  }); // Convert from Firebase User + role
  factory AppUser.fromFirebaseUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    UserRole role = UserRole.user,
    bool? skipEmailVerification,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      phoneNumber: phoneNumber,
      role: role,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      updatedAt: DateTime.now(),
      skipEmailVerification: skipEmailVerification,
    );
  } // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'skipEmailVerification': skipEmailVerification,
    };
  }

  // Convert from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      skipEmailVerification: json['skipEmailVerification'] as bool?,
    );
  } // Copy with
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    bool? skipEmailVerification,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      skipEmailVerification:
          skipEmailVerification ?? this.skipEmailVerification,
    );
  }

  // Helper methods
  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator;
  bool get isUser => role == UserRole.user;

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.moderator:
        return 'Người kiểm duyệt';
      case UserRole.user:
        return 'Người dùng';
    }
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, role: ${role.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
