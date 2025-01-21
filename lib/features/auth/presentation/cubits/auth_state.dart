import '../../domain/entities/app_user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}

class Authenticated extends AuthState {
  final AppUser user;

  Authenticated(this.user);
}

class UnAuthenticated extends AuthState {}
