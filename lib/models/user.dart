class User {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login_at': lastLoginAt?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      passwordHash: map['password_hash'],
      fullName: map['full_name'],
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.employee,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login_at'])
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, fullName: $fullName, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.fullName == fullName &&
        other.role == role &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        role.hashCode ^
        isActive.hashCode;
  }
}

enum UserRole {
  admin('Admin'),
  employee('Karyawan');

  const UserRole(this.displayName);

  final String displayName;

  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
      case 'karyawan':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isEmployee => this == UserRole.employee;
}