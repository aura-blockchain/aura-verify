import 'package:equatable/equatable.dart';

/// Verification record for history tracking
class VerificationRecord extends Equatable {
  final String id;
  final String holderDID;
  final bool isValid;
  final DateTime verifiedAt;
  final String verifiedBy;
  final String verifiedByUsername;
  final VerificationResultType resultType;
  final String? errorMessage;
  final int networkLatencyMs;
  final Map<String, dynamic> attributes;

  const VerificationRecord({
    required this.id,
    required this.holderDID,
    required this.isValid,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.verifiedByUsername,
    required this.resultType,
    this.errorMessage,
    required this.networkLatencyMs,
    this.attributes = const {},
  });

  @override
  List<Object?> get props => [
        id,
        holderDID,
        isValid,
        verifiedAt,
        verifiedBy,
        verifiedByUsername,
        resultType,
        errorMessage,
        networkLatencyMs,
        attributes,
      ];

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'holder_did': holderDID,
      'is_valid': isValid ? 1 : 0,
      'verified_at': verifiedAt.toIso8601String(),
      'verified_by': verifiedBy,
      'verified_by_username': verifiedByUsername,
      'result_type': resultType.code,
      'error_message': errorMessage,
      'network_latency_ms': networkLatencyMs,
      'attributes': attributes.toString(),
    };
  }

  factory VerificationRecord.fromDatabase(Map<String, dynamic> map) {
    return VerificationRecord(
      id: map['id'] ?? '',
      holderDID: map['holder_did'] ?? '',
      isValid: (map['is_valid'] ?? 0) == 1,
      verifiedAt: DateTime.tryParse(map['verified_at'] ?? '') ?? DateTime.now(),
      verifiedBy: map['verified_by'] ?? '',
      verifiedByUsername: map['verified_by_username'] ?? '',
      resultType: VerificationResultType.fromString(map['result_type']),
      errorMessage: map['error_message'],
      networkLatencyMs: map['network_latency_ms'] ?? 0,
      attributes: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'holder_did': holderDID,
      'is_valid': isValid,
      'verified_at': verifiedAt.toIso8601String(),
      'verified_by': verifiedBy,
      'verified_by_username': verifiedByUsername,
      'result_type': resultType.code,
      'error_message': errorMessage,
      'network_latency_ms': networkLatencyMs,
      'attributes': attributes,
    };
  }
}

enum VerificationResultType {
  success('success', 'Success'),
  failed('failed', 'Failed'),
  error('error', 'Error'),
  offline('offline', 'Offline');

  final String code;
  final String displayName;

  const VerificationResultType(this.code, this.displayName);

  static VerificationResultType fromString(String? value) {
    return VerificationResultType.values.firstWhere(
      (e) => e.code == value,
      orElse: () => VerificationResultType.error,
    );
  }
}
