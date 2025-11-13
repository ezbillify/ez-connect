import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/domain/models/integration_token.dart';

class SupabaseIntegrationTokenDatasource {
  final SupabaseClient _client;

  SupabaseIntegrationTokenDatasource(this._client);

  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return 'stk_${base64UrlEncode(values).replaceAll('=', '')}';
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  String _getTokenPrefix(String token) {
    return token.substring(0, min(8, token.length));
  }

  Future<List<IntegrationToken>> getTokens() async {
    try {
      final response = await _client
          .from('integration_tokens')
          .select()
          .order('created_at', ascending: false);

      if (response == null) {
        return [];
      }

      final tokens = (response as List)
          .map((json) => IntegrationToken.fromJson(json as Map<String, dynamic>))
          .toList();

      return tokens;
    } catch (e) {
      throw Exception('Failed to fetch integration tokens: $e');
    }
  }

  Future<IntegrationToken> getToken(String id) async {
    try {
      final response = await _client
          .from('integration_tokens')
          .select()
          .eq('id', id)
          .single();

      return IntegrationToken.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch integration token: $e');
    }
  }

  Future<IntegrationTokenWithSecret> createToken({
    required String name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = _generateToken();
      final tokenHash = _hashToken(token);
      final tokenPrefix = _getTokenPrefix(token);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.from('integration_tokens').insert({
        'name': name,
        'description': description,
        'token_hash': tokenHash,
        'token_prefix': tokenPrefix,
        'user_id': userId,
        'rate_limit_per_hour': rateLimitPerHour ?? 1000,
        'allowed_endpoints': allowedEndpoints ?? ['*'],
        'expires_at': expiresAt?.toIso8601String(),
        'metadata': metadata ?? {},
      }).select().single();

      final integrationToken =
          IntegrationToken.fromJson(response as Map<String, dynamic>);

      return IntegrationTokenWithSecret(
        token: integrationToken,
        fullToken: token,
      );
    } catch (e) {
      throw Exception('Failed to create integration token: $e');
    }
  }

  Future<IntegrationToken> updateToken({
    required String id,
    String? name,
    String? description,
    int? rateLimitPerHour,
    DateTime? expiresAt,
    List<String>? allowedEndpoints,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (rateLimitPerHour != null) {
        updates['rate_limit_per_hour'] = rateLimitPerHour;
      }
      if (expiresAt != null) updates['expires_at'] = expiresAt.toIso8601String();
      if (allowedEndpoints != null) updates['allowed_endpoints'] = allowedEndpoints;
      if (metadata != null) updates['metadata'] = metadata;

      if (updates.isEmpty) {
        return await getToken(id);
      }

      final response = await _client
          .from('integration_tokens')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return IntegrationToken.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update integration token: $e');
    }
  }

  Future<IntegrationToken> updateTokenStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _client
          .from('integration_tokens')
          .update({'status': status})
          .eq('id', id)
          .select()
          .single();

      return IntegrationToken.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update integration token status: $e');
    }
  }

  Future<IntegrationTokenWithSecret> regenerateToken(String id) async {
    try {
      final token = _generateToken();
      final tokenHash = _hashToken(token);
      final tokenPrefix = _getTokenPrefix(token);

      final response = await _client
          .from('integration_tokens')
          .update({
            'token_hash': tokenHash,
            'token_prefix': tokenPrefix,
          })
          .eq('id', id)
          .select()
          .single();

      final integrationToken =
          IntegrationToken.fromJson(response as Map<String, dynamic>);

      return IntegrationTokenWithSecret(
        token: integrationToken,
        fullToken: token,
      );
    } catch (e) {
      throw Exception('Failed to regenerate integration token: $e');
    }
  }

  Future<void> deleteToken(String id) async {
    try {
      await _client.from('integration_tokens').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete integration token: $e');
    }
  }

  Future<List<IntegrationTokenUsage>> getTokenUsage({
    String? tokenId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _client
          .from('integration_token_usage')
          .select()
          .order('created_at', ascending: false);

      if (tokenId != null) {
        query = query.eq('token_id', tokenId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      if (response == null) {
        return [];
      }

      return (response as List)
          .map((json) =>
              IntegrationTokenUsage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch token usage: $e');
    }
  }

  Future<IntegrationTokenStats> getTokenStats(String tokenId) async {
    try {
      final response = await _client
          .from('integration_token_stats')
          .select()
          .eq('token_id', tokenId)
          .single();

      return IntegrationTokenStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch token stats: $e');
    }
  }

  Future<List<IntegrationTokenStats>> getAllTokenStats() async {
    try {
      final response = await _client
          .from('integration_token_stats')
          .select()
          .order('created_at', ascending: false);

      if (response == null) {
        return [];
      }

      return (response as List)
          .map((json) =>
              IntegrationTokenStats.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch token stats: $e');
    }
  }
}
