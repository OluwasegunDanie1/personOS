/// Mirrors the backend's PublicUser shape exactly (auth/public-user.ts):
/// id, firstName, lastName, email, phone, status, lastLogin, createdAt,
/// updatedAt. Contains no password/token material.
class PublicUser {
  const PublicUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String status;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      lastLogin: json['lastLogin'] == null ? null : DateTime.parse(json['lastLogin'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'status': status,
    'lastLogin': lastLogin?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class LoginResult {
  const LoginResult({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final PublicUser user;
}

/// Mirrors POST /auth/forgot-password's response exactly: {message,
/// developmentResetToken?}. developmentResetToken is only ever present
/// outside production (Product Task 072) — never assume it exists.
class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message, required this.developmentResetToken});

  final String message;
  final String? developmentResetToken;
}
