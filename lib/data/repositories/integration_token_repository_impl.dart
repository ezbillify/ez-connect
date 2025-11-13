import 'package:app/data/datasources/supabase_integration_token_datasource.dart';
import 'package:app/domain/models/integration_token.dart';
import 'package:app/domain/repositories/integration_token_repository.dart';

class IntegrationTokenRepositoryImpl implements IntegrationTokenRepository {
  final SupabaseIntegrationTokenDatasource _datasource;

  IntegrationTokenRepositoryImpl(this._datasource);

  @override
  Future<List<IntegrationToken>> getTokens() {
    return _datasource.getTokens();
  }

  @override
  Future<IntegrationToken> getToken(String id) {
    return _datasource.getToken(id);
  }

  @override
  Future<IntegrationTokenWithSecret> createToken({
    required String name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) {
    return _datasource.createToken(
      name: name,
      description: description,
      rateLimitPerHour: rateLimitPerHour,
      expiresAt: expiresAt,
      allowedEndpoints: allowedEndpoints,
      metadata: metadata,
    );
  }

  @override
  Future<IntegrationToken> updateToken({
    required String id,
    String? name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) {
    return _datasource.updateToken(
      id: id,
      name: name,
      description: description,
      rateLimitPerHour: rateLimitPerHour,
      expiresAt: expiresAt,
      allowedEndpoints: allowedEndpoints,
      metadata: metadata,
    );
  }

  @override
  Future<IntegrationToken> updateTokenStatus({
    required String id,
    required String status,
  }) {
    return _datasource.updateTokenStatus(
      id: id,
      status: status,
    );
  }

  @override
  Future<IntegrationTokenWithSecret> regenerateToken(String id) {
    return _datasource.regenerateToken(id);
  }

  @override
  Future<void> deleteToken(String id) {
    return _datasource.deleteToken(id);
  }

  @override
  Future<List<IntegrationTokenUsage>> getTokenUsage({
    String? tokenId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return _datasource.getTokenUsage(
      tokenId: tokenId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<IntegrationTokenStats> getTokenStats(String tokenId) {
    return _datasource.getTokenStats(tokenId);
  }

  @override
  Future<List<IntegrationTokenStats>> getAllTokenStats() {
    return _datasource.getAllTokenStats();
  }
}
