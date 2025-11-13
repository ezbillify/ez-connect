class IntegrationToken {
  final String id;
  final String name;
  final String? description;
  final String tokenPrefix;
  final String userId;
  final String status;
  final int rateLimitPerHour;
  final List<String> allowedEndpoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  IntegrationToken({
    required this.id,
    required this.name,
    this.description,
    required this.tokenPrefix,
    required this.userId,
    this.status = 'active',
    this.rateLimitPerHour = 1000,
    this.allowedEndpoints = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  factory IntegrationToken.fromJson(Map<String, dynamic> json) {
    return IntegrationToken(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tokenPrefix: json['token_prefix'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'active',
      rateLimitPerHour: json['rate_limit_per_hour'] as int? ?? 1000,
      allowedEndpoints: (json['allowed_endpoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'token_prefix': tokenPrefix,
      'user_id': userId,
      'status': status,
      'rate_limit_per_hour': rateLimitPerHour,
      'allowed_endpoints': allowedEndpoints,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  IntegrationToken copyWith({
    String? id,
    String? name,
    String? description,
    String? tokenPrefix,
    String? userId,
    String? status,
    int? rateLimitPerHour,
    List<String>? allowedEndpoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return IntegrationToken(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tokenPrefix: tokenPrefix ?? this.tokenPrefix,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      rateLimitPerHour: rateLimitPerHour ?? this.rateLimitPerHour,
      allowedEndpoints: allowedEndpoints ?? this.allowedEndpoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class IntegrationTokenWithSecret {
  final IntegrationToken token;
  final String fullToken;

  IntegrationTokenWithSecret({
    required this.token,
    required this.fullToken,
  });
}

class IntegrationTokenUsage {
  final String id;
  final String tokenId;
  final String endpoint;
  final String method;
  final int statusCode;
  final int? responseTimeMs;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? requestPayload;
  final String? errorMessage;
  final DateTime createdAt;

  IntegrationTokenUsage({
    required this.id,
    required this.tokenId,
    required this.endpoint,
    required this.method,
    required this.statusCode,
    this.responseTimeMs,
    this.ipAddress,
    this.userAgent,
    this.requestPayload,
    this.errorMessage,
    required this.createdAt,
  });

  factory IntegrationTokenUsage.fromJson(Map<String, dynamic> json) {
    return IntegrationTokenUsage(
      id: json['id'] as String,
      tokenId: json['token_id'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      statusCode: json['status_code'] as int,
      responseTimeMs: json['response_time_ms'] as int?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      requestPayload: json['request_payload'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token_id': tokenId,
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'response_time_ms': responseTimeMs,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'request_payload': requestPayload,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class IntegrationTokenStats {
  final String tokenId;
  final String tokenName;
  final String status;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int totalRequests;
  final int requestsThisHour;
  final int requestsToday;
  final int errorCount;
  final double? avgResponseTimeMs;

  IntegrationTokenStats({
    required this.tokenId,
    required this.tokenName,
    required this.status,
    required this.createdAt,
    this.lastUsedAt,
    this.totalRequests = 0,
    this.requestsThisHour = 0,
    this.requestsToday = 0,
    this.errorCount = 0,
    this.avgResponseTimeMs,
  });

  factory IntegrationTokenStats.fromJson(Map<String, dynamic> json) {
    return IntegrationTokenStats(
      tokenId: json['token_id'] as String,
      tokenName: json['token_name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      totalRequests: json['total_requests'] as int? ?? 0,
      requestsThisHour: json['requests_this_hour'] as int? ?? 0,
      requestsToday: json['requests_today'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      avgResponseTimeMs: json['avg_response_time_ms'] != null
          ? (json['avg_response_time_ms'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token_id': tokenId,
      'token_name': tokenName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'total_requests': totalRequests,
      'requests_this_hour': requestsThisHour,
      'requests_today': requestsToday,
      'error_count': errorCount,
      'avg_response_time_ms': avgResponseTimeMs,
    };
  }
}

enum IntegrationTokenStatus {
  active,
  disabled,
  revoked,
}

extension IntegrationTokenStatusX on IntegrationTokenStatus {
  String get value {
    switch (this) {
      case IntegrationTokenStatus.active:
        return 'active';
      case IntegrationTokenStatus.disabled:
        return 'disabled';
      case IntegrationTokenStatus.revoked:
        return 'revoked';
    }
  }

  static IntegrationTokenStatus fromString(String value) {
    switch (value) {
      case 'active':
        return IntegrationTokenStatus.active;
      case 'disabled':
        return IntegrationTokenStatus.disabled;
      case 'revoked':
        return IntegrationTokenStatus.revoked;
      default:
        return IntegrationTokenStatus.disabled;
    }
  }
}
