import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/datasources/supabase_auth_datasource.dart';
import 'package:app/data/repositories/auth_repository_impl.dart';
import 'package:app/domain/models/auth_state.dart' as auth_state_model;
import 'package:app/domain/repositories/auth_repository.dart';

/// Provider for Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for Supabase auth datasource
final supabaseAuthDatasourceProvider = Provider<SupabaseAuthDatasource>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return SupabaseAuthDatasource(supabaseClient: supabase);
});

/// Provider for auth repository implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(supabaseAuthDatasourceProvider);
  final repository = AuthRepositoryImpl(datasource: datasource);
  
  // Initialize session on first access
  ref.onDispose(() {
    repository.dispose();
  });
  
  return repository;
});

/// State notifier for managing auth state
class AuthNotifier extends StateNotifier<auth_state_model.AuthState> {
  final AuthRepository authRepository;

  AuthNotifier({required this.authRepository}) : super(
    auth_state_model.AuthState(status: auth_state_model.AuthStatus.initial),
  ) {
    _initialize();
  }

  void _initialize() async {
    try {
      state = state.copyWith(status: auth_state_model.AuthStatus.loading);
      await authRepository.initializeSession();
      
      final user = authRepository.getCurrentUser();
      if (user != null) {
        final role = await authRepository.getUserRole();
        state = state.copyWith(
          status: auth_state_model.AuthStatus.authenticated,
          user: user,
          userRole: role,
        );
      } else {
        state = state.copyWith(status: auth_state_model.AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: auth_state_model.AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: auth_state_model.AuthStatus.loading, error: null);
      final user = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final role = await authRepository.getUserRole();
      state = state.copyWith(
        status: auth_state_model.AuthStatus.authenticated,
        user: user,
        userRole: role,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: auth_state_model.AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? invitationCode,
  }) async {
    try {
      state = state.copyWith(status: auth_state_model.AuthStatus.loading, error: null);
      final user = await authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        invitationCode: invitationCode,
      );
      final role = await authRepository.getUserRole();
      state = state.copyWith(
        status: auth_state_model.AuthStatus.authenticated,
        user: user,
        userRole: role,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: auth_state_model.AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await authRepository.requestPasswordReset(email: email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithMagicLink({required String email}) async {
    try {
      await authRepository.signInWithMagicLink(email: email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(status: auth_state_model.AuthStatus.loading);
      await authRepository.signOut();
      state = state.copyWith(
        status: auth_state_model.AuthStatus.unauthenticated,
        user: null,
        userRole: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: auth_state_model.AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, auth_state_model.AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository: authRepository);
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == auth_state_model.AuthStatus.authenticated;
});

/// Provider for getting current user
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Provider for getting current user role
final currentUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.userRole;
});

/// Provider for auth errors
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.error;
});

/// Provider for auth loading state
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == auth_state_model.AuthStatus.loading;
});
