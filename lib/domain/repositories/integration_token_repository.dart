import 'package:app/domain/models/integration_token.dart';

abstract class IntegrationTokenRepository {
  Future<List<IntegrationToken>> getTokens();
  
  Future<IntegrationToken> getToken(String id);
  
  Future<IntegrationTokenWithSecret> createToken({
    required String name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  });
  
  Future<IntegrationToken> updateToken({
    required String id,
    String? name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  });
  
  Future<IntegrationToken> updateTokenStatus({
    required String id,
    required String status,
  });
  
  Future<IntegrationTokenWithSecret> regenerateToken(String id);
  
  Future<void> deleteToken(String id);
  
  Future<List<IntegrationTokenUsage>> getTokenUsage({
    String? tokenId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  Future<IntegrationTokenStats> getTokenStats(String tokenId);
  
  Future<List<IntegrationTokenStats>> getAllTokenStats();
}
