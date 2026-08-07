import 'dart:io';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthRequested extends AuthEvent {}

class SignInRequested extends AuthEvent {
  final String phone;
  final String password;

  const SignInRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class SignUpRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String address;
  final String? email;
  final String password;
  final File? profileImage;
  final double? latitude;
  final double? longitude;

  const SignUpRequested({
    required this.fullName,
    required this.phone,
    required this.address,
    this.email,
    required this.password,
    this.profileImage,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [fullName, phone, address, email, password, profileImage, latitude, longitude];
}

class SignOutRequested extends AuthEvent {}

class UpdateUserSession extends AuthEvent {
  final AppUser user;
  const UpdateUserSession(this.user);

  @override
  List<Object?> get props => [user];
}

class UpdateProfileImageRequested extends AuthEvent {
  final String imagePath;
  const UpdateProfileImageRequested(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}