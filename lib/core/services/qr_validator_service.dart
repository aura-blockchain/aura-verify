import 'dart:convert';

/// Security-focused QR code validator for Aura credentials.
///
/// Security:
/// - Validates input before network transmission
/// - Prevents injection attacks through input sanitization
/// - Enforces size limits to prevent DoS
/// - Validates expected credential format
class QRValidatorService {
  /// Maximum allowed QR code data size (10KB)
  /// Prevents memory exhaustion attacks from oversized inputs
  static const int maxInputSize = 10 * 1024;

  /// Minimum expected QR code size
  static const int minInputSize = 50;

  /// Maximum allowed key length in JSON objects
  static const int maxKeyLength = 100;

  /// Maximum allowed string value length
  static const int maxValueLength = 2048;

  /// Maximum JSON nesting depth to prevent stack overflow
  static const int maxNestingDepth = 10;

  /// Required fields for a valid Aura credential QR code
  static const List<String> requiredFields = ['p', 'h', 'exp'];

  /// Validate QR code data before processing
  ///
  /// Returns a [QRValidationResult] with details on validity.
  /// Security: Should be called before any network operations.
  QRValidationResult validate(String? input) {
    // Null/empty check
    if (input == null || input.isEmpty) {
      return QRValidationResult.invalid(
        QRValidationError.emptyInput,
        'QR code data is empty',
      );
    }

    // Length validation
    if (input.length > maxInputSize) {
      return QRValidationResult.invalid(
        QRValidationError.tooLarge,
        'QR code data exceeds maximum allowed size',
      );
    }

    if (input.length < minInputSize) {
      return QRValidationResult.invalid(
        QRValidationError.tooSmall,
        'QR code data is too small to be a valid credential',
      );
    }

    // Check for null bytes and control characters
    if (_containsControlCharacters(input)) {
      return QRValidationResult.invalid(
        QRValidationError.invalidCharacters,
        'QR code contains invalid control characters',
      );
    }

    // Try to parse as JSON
    dynamic parsedData;
    try {
      parsedData = json.decode(input);
    } catch (e) {
      // Try base64-encoded JSON as fallback
      try {
        final decoded = utf8.decode(base64.decode(input));
        parsedData = json.decode(decoded);
      } catch (e) {
        return QRValidationResult.invalid(
          QRValidationError.invalidFormat,
          'QR code is not valid JSON or base64-encoded JSON',
        );
      }
    }

    // Validate parsed structure
    if (parsedData is! Map<String, dynamic>) {
      return QRValidationResult.invalid(
        QRValidationError.invalidStructure,
        'QR code data must be a JSON object',
      );
    }

    // Validate nesting depth
    final depth = _calculateNestingDepth(parsedData);
    if (depth > maxNestingDepth) {
      return QRValidationResult.invalid(
        QRValidationError.nestingTooDeep,
        'QR code JSON nesting exceeds maximum depth',
      );
    }

    // Validate key and value lengths
    final sizeValidation = _validateObjectSizes(parsedData);
    if (!sizeValidation.isValid) {
      return sizeValidation;
    }

    // Check required fields
    for (final field in requiredFields) {
      if (!parsedData.containsKey(field)) {
        return QRValidationResult.invalid(
          QRValidationError.missingField,
          'Required field "$field" is missing',
        );
      }
    }

    // Validate presentation ID format (p)
    final presentationId = parsedData['p'];
    if (presentationId is! String || !_isValidPresentationId(presentationId)) {
      return QRValidationResult.invalid(
        QRValidationError.invalidField,
        'Invalid presentation ID format',
      );
    }

    // Validate holder DID format (h)
    final holderDid = parsedData['h'];
    if (holderDid is! String || !_isValidDID(holderDid)) {
      return QRValidationResult.invalid(
        QRValidationError.invalidField,
        'Invalid holder DID format',
      );
    }

    // Validate expiration (exp)
    final expiration = parsedData['exp'];
    if (expiration is! int || expiration <= 0) {
      return QRValidationResult.invalid(
        QRValidationError.invalidField,
        'Invalid expiration timestamp',
      );
    }

    // Check if credential is expired
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expiration * 1000);
    if (expirationDate.isBefore(DateTime.now())) {
      return QRValidationResult.invalid(
        QRValidationError.expired,
        'Credential has expired',
      );
    }

    // Validate nonce if present
    if (parsedData.containsKey('n')) {
      final nonce = parsedData['n'];
      if (nonce is! int && nonce is! String) {
        return QRValidationResult.invalid(
          QRValidationError.invalidField,
          'Invalid nonce format',
        );
      }
    }

    // Validate signature if present
    if (parsedData.containsKey('s')) {
      final signature = parsedData['s'];
      if (signature is! String || !_isValidSignature(signature)) {
        return QRValidationResult.invalid(
          QRValidationError.invalidSignature,
          'Invalid signature format',
        );
      }
    }

    return QRValidationResult.valid(
      sanitizedData: input,
      parsedData: parsedData,
      holderDid: holderDid,
      presentationId: presentationId,
      expiresAt: expirationDate,
    );
  }

  /// Sanitize input before transmission
  /// Removes potential injection characters while preserving valid data
  String sanitize(String input) {
    // Remove null bytes
    var sanitized = input.replaceAll('\x00', '');

    // Remove other control characters except newlines and tabs
    sanitized = sanitized.replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Check for control characters that shouldn't be in valid QR data
  bool _containsControlCharacters(String input) {
    // Allow newlines, tabs but reject null bytes and other control chars
    final controlPattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
    return controlPattern.hasMatch(input);
  }

  /// Calculate JSON nesting depth
  int _calculateNestingDepth(dynamic obj, [int currentDepth = 0]) {
    if (obj is Map) {
      if (obj.isEmpty) return currentDepth + 1;
      return obj.values
          .map((v) => _calculateNestingDepth(v, currentDepth + 1))
          .reduce((a, b) => a > b ? a : b);
    } else if (obj is List) {
      if (obj.isEmpty) return currentDepth + 1;
      return obj
          .map((v) => _calculateNestingDepth(v, currentDepth + 1))
          .reduce((a, b) => a > b ? a : b);
    }
    return currentDepth;
  }

  /// Validate key and value sizes in parsed object
  QRValidationResult _validateObjectSizes(Map<String, dynamic> obj, [int depth = 0]) {
    for (final entry in obj.entries) {
      // Check key length
      if (entry.key.length > maxKeyLength) {
        return QRValidationResult.invalid(
          QRValidationError.keyTooLong,
          'JSON key exceeds maximum length',
        );
      }

      // Check string value length
      if (entry.value is String && (entry.value as String).length > maxValueLength) {
        return QRValidationResult.invalid(
          QRValidationError.valueTooLong,
          'JSON value exceeds maximum length',
        );
      }

      // Recurse into nested objects
      if (entry.value is Map<String, dynamic>) {
        final nested = _validateObjectSizes(entry.value as Map<String, dynamic>, depth + 1);
        if (!nested.isValid) return nested;
      }

      // Check list items
      if (entry.value is List) {
        for (final item in entry.value as List) {
          if (item is Map<String, dynamic>) {
            final nested = _validateObjectSizes(item, depth + 1);
            if (!nested.isValid) return nested;
          } else if (item is String && item.length > maxValueLength) {
            return QRValidationResult.invalid(
              QRValidationError.valueTooLong,
              'JSON array value exceeds maximum length',
            );
          }
        }
      }
    }

    return QRValidationResult.valid(sanitizedData: '', parsedData: obj);
  }

  /// Validate presentation ID format
  /// Expected format: UUID or "pres:<uuid>" or similar
  bool _isValidPresentationId(String id) {
    // Must be alphanumeric with hyphens, colons, underscores
    final pattern = RegExp(r'^[a-zA-Z0-9:_-]{8,128}$');
    return pattern.hasMatch(id);
  }

  /// Validate DID format
  /// Expected format: did:<method>:<identifier>
  bool _isValidDID(String did) {
    // DID format: did:<method>:<method-specific-id>
    final pattern = RegExp(r'^did:[a-z0-9]+:[a-zA-Z0-9._:-]+$');
    return pattern.hasMatch(did);
  }

  /// Validate signature format (base64 or hex)
  bool _isValidSignature(String signature) {
    // Base64 or hex encoded signature
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+=*$');
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');

    if (signature.length < 32 || signature.length > 512) {
      return false;
    }

    return base64Pattern.hasMatch(signature) || hexPattern.hasMatch(signature);
  }
}

/// Result of QR code validation
class QRValidationResult {
  final bool isValid;
  final QRValidationError? error;
  final String? errorMessage;
  final String? sanitizedData;
  final Map<String, dynamic>? parsedData;
  final String? holderDid;
  final String? presentationId;
  final DateTime? expiresAt;

  QRValidationResult._({
    required this.isValid,
    this.error,
    this.errorMessage,
    this.sanitizedData,
    this.parsedData,
    this.holderDid,
    this.presentationId,
    this.expiresAt,
  });

  factory QRValidationResult.valid({
    required String sanitizedData,
    required Map<String, dynamic> parsedData,
    String? holderDid,
    String? presentationId,
    DateTime? expiresAt,
  }) {
    return QRValidationResult._(
      isValid: true,
      sanitizedData: sanitizedData,
      parsedData: parsedData,
      holderDid: holderDid,
      presentationId: presentationId,
      expiresAt: expiresAt,
    );
  }

  factory QRValidationResult.invalid(QRValidationError error, String message) {
    return QRValidationResult._(
      isValid: false,
      error: error,
      errorMessage: message,
    );
  }
}

/// Types of validation errors
enum QRValidationError {
  emptyInput,
  tooLarge,
  tooSmall,
  invalidCharacters,
  invalidFormat,
  invalidStructure,
  nestingTooDeep,
  keyTooLong,
  valueTooLong,
  missingField,
  invalidField,
  invalidSignature,
  expired,
}
