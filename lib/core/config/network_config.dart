/// Network endpoints and configuration
/// Security: HTTPS is enforced for all non-local environments
class NetworkConfig {
  // Base URLs - all use HTTPS except localhost for local dev
  static const String productionBaseUrl = 'https://api.aura-blockchain.com';
  static const String stagingBaseUrl = 'https://staging-api.aura-blockchain.com';
  // Security: Use HTTPS for local development too (via mkcert or similar)
  // Set ALLOW_INSECURE_LOCAL=true to use HTTP for localhost only
  static const String developmentBaseUrl = 'https://localhost:8080';

  /// Whether insecure localhost is allowed (dev only)
  static const bool _allowInsecureLocal = bool.fromEnvironment(
    'ALLOW_INSECURE_LOCAL',
    defaultValue: false,
  );

  // Get the current base URL based on environment
  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    String url;
    switch (env) {
      case 'production':
        url = productionBaseUrl;
        break;
      case 'staging':
        url = stagingBaseUrl;
        break;
      default:
        // In development, allow HTTP only for localhost if explicitly enabled
        if (_allowInsecureLocal) {
          url = 'http://localhost:8080';
          _logLocalhostWarning();
        } else {
          url = developmentBaseUrl;
        }
    }

    // Validate URL security before returning
    validateSecureUrl(url);
    return url;
  }

  /// Validate that a URL uses HTTPS (security enforcement)
  /// Throws if URL is not secure
  /// Similar to validateTLSEndpoint() for gRPC
  static void validateSecureUrl(String url) {
    final uri = Uri.parse(url);

    // HTTPS is always allowed
    if (uri.scheme == 'https') {
      return;
    }

    // HTTP only allowed for localhost in development with explicit flag
    if (uri.scheme == 'http') {
      final isLocalhost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';

      if (isLocalhost && _allowInsecureLocal) {
        // Allow but log warning (handled by caller)
        return;
      }

      throw SecurityException(
        'Security: HTTPS required. URL "$url" must use HTTPS. '
        'HTTP is only allowed for localhost with ALLOW_INSECURE_LOCAL=true.',
      );
    }

    throw SecurityException('Unsupported URL scheme: ${uri.scheme}');
  }

  /// Validate gRPC endpoint uses TLS (grpcs://)
  /// Throws if endpoint is not secure
  /// Production/staging MUST use grpcs://, localhost can use grpc:// with warning
  static void validateTLSEndpoint(String endpoint) {
    // Check if endpoint has protocol prefix
    if (endpoint.startsWith('grpcs://')) {
      return; // Secure gRPC with TLS
    }

    if (endpoint.startsWith('grpc://')) {
      // Parse to check if it's localhost
      final uri = Uri.parse(endpoint);
      final isLocalhost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';

      if (isLocalhost && _allowInsecureLocal) {
        _logLocalhostWarning();
        return;
      }

      throw SecurityException(
        'Security: TLS required for gRPC. Endpoint "$endpoint" must use grpcs:// protocol. '
        'grpc:// is only allowed for localhost with ALLOW_INSECURE_LOCAL=true.',
      );
    }

    // No protocol prefix - assume host:port format, add validation
    final isLocalhost = endpoint.startsWith('localhost:') ||
        endpoint.startsWith('127.0.0.1:') ||
        endpoint.startsWith('[::1]:');

    if (isLocalhost && _allowInsecureLocal) {
      _logLocalhostWarning();
      return;
    }

    // For production/staging, require explicit grpcs:// protocol
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    if (env == 'production' || env == 'staging') {
      throw SecurityException(
        'Security: gRPC endpoint "$endpoint" must use grpcs:// protocol in $env environment.',
      );
    }
  }

  /// Log warning when using insecure localhost connection
  static void _logLocalhostWarning() {
    // In production builds, this should use proper logging
    // For now, using print for development visibility
    print('WARNING: Using insecure HTTP/gRPC connection to localhost. '
        'This is only allowed in development with ALLOW_INSECURE_LOCAL=true. '
        'Production deployments MUST use HTTPS/grpcs.');
  }

  /// Check if current configuration uses secure transport
  static bool get isSecure {
    try {
      validateSecureUrl(baseUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  // API Endpoints
  static const String verifyCredentialEndpoint = '/api/v1/verify/credential';
  static const String validateProofEndpoint = '/api/v1/verify/proof';
  static const String checkRevocationEndpoint = '/api/v1/verify/revocation';
  static const String healthCheckEndpoint = '/api/v1/health';

  // Full URLs
  static String get verifyCredentialUrl => '$baseUrl$verifyCredentialEndpoint';
  static String get validateProofUrl => '$baseUrl$validateProofEndpoint';
  static String get checkRevocationUrl => '$baseUrl$checkRevocationEndpoint';
  static String get healthCheckUrl => '$baseUrl$healthCheckEndpoint';

  // Timeout Configuration
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 10;
  static const int sendTimeoutSeconds = 10;

  // Retry Configuration
  static const int maxRetries = 3;
  static const int retryDelayMilliseconds = 1000;

  // Headers
  static const String apiKeyHeader = 'X-API-Key';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String userAgentHeader = 'User-Agent';
  static const String userAgent = 'AuraVerifyBusiness/1.0.0';

  // API Key - MUST be provided via environment variable
  // Security: No hardcoded fallback - fails securely if not configured
  static const String _apiKeyEnv = String.fromEnvironment('AURA_API_KEY');

  /// Get API key securely
  /// Throws in production if not configured
  static String get apiKey {
    if (_apiKeyEnv.isNotEmpty) {
      return _apiKeyEnv;
    }
    // Only allow empty API key in development mode
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    if (env == 'development') {
      return ''; // Allow empty for local development
    }
    throw StateError('AURA_API_KEY environment variable is required in production/staging');
  }

  /// Check if API key is configured
  static bool get hasApiKey => _apiKeyEnv.isNotEmpty;

  // Common Headers
  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      contentTypeHeader: contentTypeJson,
      userAgentHeader: userAgent,
    };
    // Only add API key header if configured
    if (hasApiKey) {
      headers[apiKeyHeader] = apiKey;
    }
    return headers;
  }

  NetworkConfig._(); // Private constructor to prevent instantiation
}

/// Security exception for transport layer violations
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
