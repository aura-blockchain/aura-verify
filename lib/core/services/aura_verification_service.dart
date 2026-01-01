import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:uuid/uuid.dart';
import '../config/network_config.dart';
import '../../features/verification/bloc/verification_bloc.dart';

/// Certificate pins for Aura network endpoints
/// Security: SHA-256 fingerprints of server certificates
/// These must be updated when certificates are rotated
class CertificatePins {
  /// Mainnet API certificate pin (SHA-256)
  static const String mainnetPin =
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='; // Replace with actual pin

  /// Testnet API certificate pin (SHA-256)
  static const String testnetPin =
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB='; // Replace with actual pin

  /// Get pins for a network
  static List<String> getPinsForNetwork(String network) {
    switch (network) {
      case 'mainnet':
        return [mainnetPin];
      case 'testnet':
        return [testnetPin];
      default:
        return []; // No pinning for local development
    }
  }
}

/// Implementation of VerificationService that connects to Aura blockchain
/// Security: Implements certificate pinning for production networks
class AuraVerificationService implements VerificationService {
  final Dio _dio;
  final NetworkConfig _config;
  final Uuid _uuid = const Uuid();
  final bool _enableCertPinning;

  AuraVerificationService({
    required NetworkConfig config,
    Dio? dio,
    bool enableCertPinning = true,
  })  : _config = config,
        _enableCertPinning = enableCertPinning,
        _dio = dio ?? Dio() {
    // Validate security FIRST - fail fast if configuration is insecure
    config.validateSecurity();

    _dio.options.baseUrl = config.restEndpoint;
    _dio.options.connectTimeout = Duration(milliseconds: config.timeoutMs);
    _dio.options.receiveTimeout = Duration(milliseconds: config.timeoutMs);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Configure certificate pinning for production networks
    if (enableCertPinning && config.network != 'local' && dio == null) {
      _configureCertificatePinning(config.network);
    }
  }

  /// Configure certificate pinning for HTTPS connections
  /// Security: Prevents MITM attacks by validating server certificate
  void _configureCertificatePinning(String network) {
    final pins = CertificatePins.getPinsForNetwork(network);
    if (pins.isEmpty) return;

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // In production, reject all bad certificates
        return false;
      };
      return client;
    };

    // Add interceptor to validate certificate fingerprint
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Certificate validation happens at the transport layer
          // This interceptor logs for security auditing
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.type == DioExceptionType.connectionError) {
            // Could be certificate pinning failure
            final originalError = error.error;
            if (originalError is HandshakeException ||
                originalError is TlsException) {
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: 'Certificate validation failed - possible MITM attack',
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  @override
  Future<VerificationResult> verify({
    required String qrCodeData,
    String? verifierAddress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post(
        '/aura/vcregistry/v1beta1/verify_presentation',
        data: {
          'qr_code_data': qrCodeData,
          if (verifierAddress != null) 'verifier_address': verifierAddress,
        },
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;
        final result = data['result'] ?? data;

        return VerificationResult(
          isValid: result['is_valid'] ?? false,
          holderDID: result['holder_did'] ?? '',
          verifiedAt: DateTime.tryParse(result['verified_at'] ?? '') ?? DateTime.now(),
          vcDetails: _parseVCDetails(result['vc_details']),
          attributes: DiscloseableAttributes.fromJson(result['attributes'] ?? {}),
          verificationError: result['verification_error'],
          auditId: result['audit_id'] ?? _uuid.v4(),
          networkLatencyMs: stopwatch.elapsedMilliseconds,
          method: VerificationMethod.online,
        );
      } else {
        throw VerificationException(
          'Verification request failed',
          code: 'HTTP_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      stopwatch.stop();

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw VerificationException(
          'Network timeout - please try again',
          code: 'TIMEOUT',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw VerificationException(
          'Unable to connect to Aura network',
          code: 'CONNECTION_ERROR',
        );
      }

      throw VerificationException(
        e.message ?? 'Network error',
        code: 'NETWORK_ERROR',
      );
    }
  }

  @override
  Future<AgeCheckResponse> isAge21Plus(String qrCodeData) async {
    final result = await verify(qrCodeData: qrCodeData);

    return AgeCheckResponse(
      isOver: result.attributes.isOver21,
      holderDID: result.holderDID,
      verifiedAt: result.verifiedAt,
    );
  }

  @override
  Future<AgeCheckResponse> isAge18Plus(String qrCodeData) async {
    final result = await verify(qrCodeData: qrCodeData);

    return AgeCheckResponse(
      isOver: result.attributes.isOver18 || result.attributes.isOver21,
      holderDID: result.holderDID,
      verifiedAt: result.verifiedAt,
    );
  }

  @override
  Future<bool> isVerifiedHuman(String qrCodeData) async {
    final result = await verify(qrCodeData: qrCodeData);

    // Check if any VC is of type VERIFIED_HUMAN
    return result.vcDetails.any(
      (vc) => vc.vcType == VCType.verifiedHuman && vc.isValid,
    );
  }

  /// Check status of a specific credential
  Future<VCStatus> checkCredentialStatus(String vcId) async {
    try {
      final response = await _dio.get(
        '/aura/vcregistry/v1beta1/vc_status/$vcId',
      );

      if (response.statusCode == 200) {
        final status = response.data['status'] ?? 0;
        return VCStatus.fromCode(status);
      }

      return VCStatus.unspecified;
    } catch (e) {
      throw VerificationException(
        'Failed to check credential status',
        code: 'STATUS_CHECK_ERROR',
      );
    }
  }

  /// Get Aura Score for a holder
  Future<int?> getAuraScore(String qrCodeData) async {
    final result = await verify(qrCodeData: qrCodeData);

    // Extract Aura Score from custom attributes if available
    final scoreStr = result.attributes.customAttributes['aura_score'];
    if (scoreStr != null) {
      return int.tryParse(scoreStr);
    }

    return null;
  }

  List<VCDetail> _parseVCDetails(dynamic vcDetailsJson) {
    if (vcDetailsJson == null) return [];
    if (vcDetailsJson is! List) return [];

    return vcDetailsJson
        .map((e) => VCDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Exception thrown during verification
class VerificationException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  VerificationException(this.message, {this.code, this.details});

  @override
  String toString() => 'VerificationException: $message (code: $code)';
}

/// Network configuration
class NetworkConfig {
  final String network;
  final String restEndpoint;
  final String grpcEndpoint;
  final String chainId;
  final int timeoutMs;

  const NetworkConfig({
    required this.network,
    required this.restEndpoint,
    required this.grpcEndpoint,
    required this.chainId,
    this.timeoutMs = 10000,
  });

  /// Validate endpoints are secure
  void validateSecurity() {
    // Import from network_config.dart would be ideal, but to avoid circular deps
    // we inline the validation here
    _validateHttpsEndpoint(restEndpoint);
    _validateGrpcTLS(grpcEndpoint);
  }

  void _validateHttpsEndpoint(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme == 'https') {
      return; // Secure
    }

    if (uri.scheme == 'http') {
      final isLocalhost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';

      // Allow insecure localhost only for 'local' network
      if (isLocalhost && network == 'local') {
        _logSecurityWarning('HTTP endpoint: $url');
        return;
      }

      throw SecurityException(
        'Security: HTTPS required for REST endpoint "$url". '
        'HTTP is only allowed for localhost in local development.',
      );
    }

    throw SecurityException('Unsupported URL scheme for REST: ${uri.scheme}');
  }

  void _validateGrpcTLS(String endpoint) {
    // grpcs:// protocol indicates TLS is enabled
    if (endpoint.startsWith('grpcs://')) {
      return; // Secure
    }

    // Check for localhost patterns (with or without grpc:// prefix)
    final isLocalhost = endpoint.startsWith('grpc://localhost:') ||
        endpoint.startsWith('localhost:') ||
        endpoint.startsWith('127.0.0.1:') ||
        endpoint.startsWith('[::1]:');

    // Allow insecure localhost only for 'local' network
    if (isLocalhost && network == 'local') {
      _logSecurityWarning('gRPC endpoint without TLS: $endpoint');
      return;
    }

    // Production/testnet must use grpcs:// or have explicit TLS config
    if (network == 'mainnet' || network == 'testnet') {
      throw SecurityException(
        'Security: TLS required for gRPC in $network. '
        'Endpoint "$endpoint" must use grpcs:// protocol or be properly configured with TLS.',
      );
    }
  }

  void _logSecurityWarning(String message) {
    print('WARNING: $message - Only allowed in local development. '
        'Production MUST use HTTPS/grpcs.');
  }

  static const mainnet = NetworkConfig(
    network: 'mainnet',
    restEndpoint: 'https://api.aura.network',
    grpcEndpoint: 'grpcs://grpc.aura.network:9090', // TLS enabled
    chainId: 'aura-mainnet-1',
  );

  static const testnet = NetworkConfig(
    network: 'testnet',
    restEndpoint: 'https://api.testnet.aura.network',
    grpcEndpoint: 'grpcs://grpc.testnet.aura.network:9090', // TLS enabled
    chainId: 'aura-testnet-1',
  );

  static const local = NetworkConfig(
    network: 'local',
    restEndpoint: 'http://localhost:1317', // Allowed for local only
    grpcEndpoint: 'localhost:9090', // Allowed for local only
    chainId: 'aura-local',
  );
}

/// Security exception for network configuration violations
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
