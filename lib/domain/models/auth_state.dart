import 'package:app/domain/models/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final String? userRole;

  AuthState({
    required this.status,
    this.user,
    this.error,
    this.userRole,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    String? userRole,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.id}, error: $error, userRole: $userRole)';
}
