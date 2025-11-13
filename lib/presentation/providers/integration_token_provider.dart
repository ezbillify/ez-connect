import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/datasources/supabase_integration_token_datasource.dart';
import 'package:app/data/repositories/integration_token_repository_impl.dart';
import 'package:app/domain/models/integration_token.dart';
import 'package:app/domain/repositories/integration_token_repository.dart';
import 'package:app/presentation/providers/auth_provider.dart';

final integrationTokenDatasourceProvider =
    Provider<SupabaseIntegrationTokenDatasource>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return SupabaseIntegrationTokenDatasource(supabase);
});

final integrationTokenRepositoryProvider =
    Provider<IntegrationTokenRepository>((ref) {
  final datasource = ref.watch(integrationTokenDatasourceProvider);
  return IntegrationTokenRepositoryImpl(datasource);
});

class IntegrationTokenState {
  final List<IntegrationToken> tokens;
  final bool isLoading;
  final String? error;
  final IntegrationTokenWithSecret? newlyCreatedToken;

  IntegrationTokenState({
    this.tokens = const [],
    this.isLoading = false,
    this.error,
    this.newlyCreatedToken,
  });

  IntegrationTokenState copyWith({
    List<IntegrationToken>? tokens,
    bool? isLoading,
    String? error,
    IntegrationTokenWithSecret? newlyCreatedToken,
    bool clearNewToken = false,
    bool clearError = false,
  }) {
    return IntegrationTokenState(
      tokens: tokens ?? this.tokens,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      newlyCreatedToken: clearNewToken ? null : (newlyCreatedToken ?? this.newlyCreatedToken),
    );
  }
}

class IntegrationTokenNotifier extends StateNotifier<IntegrationTokenState> {
  final IntegrationTokenRepository repository;

  IntegrationTokenNotifier(this.repository) : super(IntegrationTokenState()) {
    loadTokens();
  }

  Future<void> loadTokens() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokens = await repository.getTokens();
      state = state.copyWith(tokens: tokens, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tokens: $e',
      );
    }
  }

  Future<void> createToken({
    required String name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokenWithSecret = await repository.createToken(
        name: name,
        description: description,
        rateLimitPerHour: rateLimitPerHour,
        expiresAt: expiresAt,
        allowedEndpoints: allowedEndpoints,
        metadata: metadata,
      );

      final updatedTokens = [tokenWithSecret.token, ...state.tokens];
      state = state.copyWith(
        tokens: updatedTokens,
        isLoading: false,
        newlyCreatedToken: tokenWithSecret,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create token: $e',
      );
    }
  }

  Future<void> updateToken({
    required String id,
    String? name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedToken = await repository.updateToken(
        id: id,
        name: name,
        description: description,
        rateLimitPerHour: rateLimitPerHour,
        expiresAt: expiresAt,
        allowedEndpoints: allowedEndpoints,
        metadata: metadata,
      );

      final updatedTokens = state.tokens
          .map((token) => token.id == id ? updatedToken : token)
          .toList();

      state = state.copyWith(tokens: updatedTokens, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update token: $e',
      );
    }
  }

  Future<void> updateTokenStatus({
    required String id,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedToken = await repository.updateTokenStatus(
        id: id,
        status: status,
      );

      final updatedTokens = state.tokens
          .map((token) => token.id == id ? updatedToken : token)
          .toList();

      state = state.copyWith(tokens: updatedTokens, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update token status: $e',
      );
    }
  }

  Future<void> regenerateToken(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tokenWithSecret = await repository.regenerateToken(id);

      final updatedTokens = state.tokens
          .map((token) => token.id == id ? tokenWithSecret.token : token)
          .toList();

      state = state.copyWith(
        tokens: updatedTokens,
        isLoading: false,
        newlyCreatedToken: tokenWithSecret,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to regenerate token: $e',
      );
    }
  }

  Future<void> deleteToken(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.deleteToken(id);

      final updatedTokens = state.tokens.where((token) => token.id != id).toList();
      state = state.copyWith(tokens: updatedTokens, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete token: $e',
      );
    }
  }

  void clearNewToken() {
    state = state.copyWith(clearNewToken: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final integrationTokenProvider =
    StateNotifierProvider<IntegrationTokenNotifier, IntegrationTokenState>((ref) {
  final repository = ref.watch(integrationTokenRepositoryProvider);
  return IntegrationTokenNotifier(repository);
});

final integrationTokenUsageProvider = FutureProvider.autoDispose
    .family<List<IntegrationTokenUsage>, String?>((ref, tokenId) async {
  final repository = ref.watch(integrationTokenRepositoryProvider);
  return repository.getTokenUsage(
    tokenId: tokenId,
    limit: 100,
  );
});

final integrationTokenStatsProvider = FutureProvider.autoDispose
    .family<IntegrationTokenStats, String>((ref, tokenId) async {
  final repository = ref.watch(integrationTokenRepositoryProvider);
  return repository.getTokenStats(tokenId);
});

final allIntegrationTokenStatsProvider =
    FutureProvider.autoDispose<List<IntegrationTokenStats>>((ref) async {
  final repository = ref.watch(integrationTokenRepositoryProvider);
  return repository.getAllTokenStats();
});
