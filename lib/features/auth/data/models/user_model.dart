import 'package:shopsphere/features/auth/domain/entities/user.dart';

/// DTO for the DummyJSON user payload (login response and `/auth/me`).
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.image,
    super.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] as num).toInt(),
    username: json['username'] as String,
    email: json['email'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    image: json['image'] as String? ?? '',
    phone: json['phone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'image': image,
    'phone': phone,
  };
}

/// Response of `POST /auth/login`: tokens plus the user's basic fields.
class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserModel.fromJson(json),
      );

  final String accessToken;
  final String refreshToken;
  final UserModel user;
}
