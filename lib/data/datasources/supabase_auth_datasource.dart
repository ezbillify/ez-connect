import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/domain/models/user.dart';

class SupabaseAuthDatasource {
  final SupabaseClient supabaseClient;

  SupabaseAuthDatasource({required this.supabaseClient});

  /// Get the Supabase auth instance
  GoTrueClient get auth => supabaseClient.auth;

  /// Get the current session
  Session? getCurrentSession() {
    return auth.currentSession;
  }

  /// Get the current user from auth
  User? getCurrentUser() {
    final authUser = auth.currentUser;
    if (authUser == null) return null;

    return User(
      id: authUser.id,
      email: authUser.email ?? '',
      name: authUser.userMetadata?['name'] ?? authUser.email ?? '',
      avatarUrl: authUser.userMetadata?['avatar_url'],
      createdAt: authUser.createdAt,
      updatedAt: authUser.updatedAt,
    );
  }

  /// Sign in with email and password
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign in failed: User is null');
    }

    return _mapAuthUserToUser(response.user!);
  }

  /// Sign up with email and password
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed: User is null');
    }

    return _mapAuthUserToUser(response.user!);
  }

  /// Request password reset
  Future<void> requestPasswordReset({required String email}) async {
    await auth.resetPasswordForEmail(email);
  }

  /// Reset password with the reset token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign in with magic link
  Future<void> signInWithMagicLink({required String email}) async {
    await auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.flutter://callback',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Refresh session
  Future<bool> refreshSession() async {
    final session = getCurrentSession();
    if (session == null) {
      return false;
    }

    try {
      final response = await auth.refreshSession();
      return response.session != null;
    } catch (e) {
      return false;
    }
  }

  /// Fetch user profile from profiles table
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await supabaseClient
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  /// Check if user has invitation code
  Future<bool> validateInvitationCode(String code) async {
    try {
      final response = await supabaseClient
          .from('invitations')
          .select('id')
          .eq('code', code)
          .eq('used', false)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Mark invitation as used
  Future<void> markInvitationAsUsed(String code) async {
    await supabaseClient
        .from('invitations')
        .update({'used': true})
        .eq('code', code);
  }

  /// Stream auth state changes
  Stream<dynamic> authStateChanges() {
    return auth.onAuthStateChange;
  }

  /// Helper to map Supabase User to domain User
  User _mapAuthUserToUser(AuthUser authUser) {
    return User(
      id: authUser.id,
      email: authUser.email ?? '',
      name: authUser.userMetadata?['name'] ?? authUser.email ?? '',
      avatarUrl: authUser.userMetadata?['avatar_url'],
      createdAt: authUser.createdAt,
      updatedAt: authUser.updatedAt,
    );
  }
}
