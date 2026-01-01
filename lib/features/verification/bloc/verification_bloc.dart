import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

class VerifyQRCode extends VerificationEvent {
  final String qrCodeData;
  final String? verifierAddress;

  const VerifyQRCode({
    required this.qrCodeData,
    this.verifierAddress,
  });

  @override
  List<Object?> get props => [qrCodeData, verifierAddress];
}

class ResetVerification extends VerificationEvent {
  const ResetVerification();
}

class CheckAge21 extends VerificationEvent {
  final String qrCodeData;

  const CheckAge21({required this.qrCodeData});

  @override
  List<Object?> get props => [qrCodeData];
}

class CheckAge18 extends VerificationEvent {
  final String qrCodeData;

  const CheckAge18({required this.qrCodeData});

  @override
  List<Object?> get props => [qrCodeData];
}

// States
abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {
  const VerificationInitial();
}

class VerificationLoading extends VerificationState {
  final String message;

  const VerificationLoading({this.message = 'Verifying...'});

  @override
  List<Object?> get props => [message];
}

class VerificationSuccess extends VerificationState {
  final VerificationResult result;

  const VerificationSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class VerificationFailure extends VerificationState {
  final String error;
  final String? errorCode;
  final VerificationResult? partialResult;

  const VerificationFailure({
    required this.error,
    this.errorCode,
    this.partialResult,
  });

  @override
  List<Object?> get props => [error, errorCode, partialResult];
}

class AgeCheckResult extends VerificationState {
  final bool isOverAge;
  final int ageThreshold;
  final String holderDID;
  final DateTime verifiedAt;

  const AgeCheckResult({
    required this.isOverAge,
    required this.ageThreshold,
    required this.holderDID,
    required this.verifiedAt,
  });

  @override
  List<Object?> get props => [isOverAge, ageThreshold, holderDID, verifiedAt];
}

// Models
class VerificationResult {
  final bool isValid;
  final String holderDID;
  final DateTime verifiedAt;
  final List<VCDetail> vcDetails;
  final DiscloseableAttributes attributes;
  final String? verificationError;
  final String auditId;
  final int networkLatencyMs;
  final VerificationMethod method;

  VerificationResult({
    required this.isValid,
    required this.holderDID,
    required this.verifiedAt,
    required this.vcDetails,
    required this.attributes,
    this.verificationError,
    required this.auditId,
    required this.networkLatencyMs,
    required this.method,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isValid: json['is_valid'] ?? false,
      holderDID: json['holder_did'] ?? '',
      verifiedAt: DateTime.tryParse(json['verified_at'] ?? '') ?? DateTime.now(),
      vcDetails: (json['vc_details'] as List<dynamic>?)
              ?.map((e) => VCDetail.fromJson(e))
              .toList() ??
          [],
      attributes: DiscloseableAttributes.fromJson(json['attributes'] ?? {}),
      verificationError: json['verification_error'],
      auditId: json['audit_id'] ?? const Uuid().v4(),
      networkLatencyMs: json['network_latency_ms'] ?? 0,
      method: VerificationMethod.fromString(json['verification_method']),
    );
  }
}

class VCDetail {
  final String vcId;
  final VCType vcType;
  final VCStatus status;
  final bool isValid;
  final bool isExpired;
  final bool isRevoked;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  VCDetail({
    required this.vcId,
    required this.vcType,
    required this.status,
    required this.isValid,
    required this.isExpired,
    required this.isRevoked,
    this.issuedAt,
    this.expiresAt,
  });

  factory VCDetail.fromJson(Map<String, dynamic> json) {
    return VCDetail(
      vcId: json['vc_id'] ?? '',
      vcType: VCType.fromCode(json['vc_type'] ?? 0),
      status: VCStatus.fromCode(json['status'] ?? 0),
      isValid: json['is_valid'] ?? false,
      isExpired: json['is_expired'] ?? false,
      isRevoked: json['is_revoked'] ?? false,
      issuedAt: DateTime.tryParse(json['issued_at'] ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? ''),
    );
  }
}

class DiscloseableAttributes {
  final String? fullName;
  final int? age;
  final bool isOver18;
  final bool isOver21;
  final String? fullAddress;
  final String? cityState;
  final Map<String, String> customAttributes;

  DiscloseableAttributes({
    this.fullName,
    this.age,
    this.isOver18 = false,
    this.isOver21 = false,
    this.fullAddress,
    this.cityState,
    this.customAttributes = const {},
  });

  factory DiscloseableAttributes.fromJson(Map<String, dynamic> json) {
    return DiscloseableAttributes(
      fullName: json['full_name'],
      age: json['age'],
      isOver18: json['is_over_18'] ?? false,
      isOver21: json['is_over_21'] ?? false,
      fullAddress: json['full_address'],
      cityState: json['city_state'],
      customAttributes: Map<String, String>.from(json['custom_attributes'] ?? {}),
    );
  }
}

enum VCType {
  unspecified(0, 'Unspecified'),
  verifiedHuman(1, 'Verified Human'),
  ageOver18(2, 'Age 18+'),
  ageOver21(3, 'Age 21+'),
  residentOf(4, 'Resident'),
  biometricAuth(5, 'Biometric'),
  kycVerification(6, 'KYC'),
  professionalLicense(8, 'Professional');

  final int code;
  final String displayName;

  const VCType(this.code, this.displayName);

  static VCType fromCode(int code) {
    return VCType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => VCType.unspecified,
    );
  }
}

enum VCStatus {
  unspecified(0, 'Unknown'),
  pending(1, 'Pending'),
  active(2, 'Active'),
  revoked(3, 'Revoked'),
  expired(4, 'Expired'),
  suspended(5, 'Suspended');

  final int code;
  final String displayName;

  const VCStatus(this.code, this.displayName);

  static VCStatus fromCode(int code) {
    return VCStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => VCStatus.unspecified,
    );
  }
}

enum VerificationMethod {
  online,
  offline,
  cached;

  static VerificationMethod fromString(String? value) {
    switch (value) {
      case 'offline':
        return VerificationMethod.offline;
      case 'cached':
        return VerificationMethod.cached;
      default:
        return VerificationMethod.online;
    }
  }
}

// BLoC
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationService _verificationService;

  /// Maximum allowed QR code length
  /// Security: Prevents buffer overflow and DoS attacks
  static const int _maxQRCodeLength = 8192;

  /// Maximum URL length for aura:// scheme
  static const int _maxUrlLength = 4096;

  VerificationBloc({
    required VerificationService verificationService,
  })  : _verificationService = verificationService,
        super(const VerificationInitial()) {
    on<VerifyQRCode>(_onVerifyQRCode);
    on<ResetVerification>(_onResetVerification);
    on<CheckAge21>(_onCheckAge21);
    on<CheckAge18>(_onCheckAge18);
  }

  /// Validate QR code input
  /// Security: Prevents malicious input, oversized data, and injection attacks
  String? _validateQRCodeInput(String qrCodeData) {
    // Check for empty input
    if (qrCodeData.isEmpty) {
      return 'QR code data cannot be empty';
    }

    // Check maximum length
    if (qrCodeData.length > _maxQRCodeLength) {
      return 'QR code data exceeds maximum allowed size';
    }

    // Check for null bytes (potential injection attack)
    if (qrCodeData.contains('\x00')) {
      return 'Invalid QR code: contains null bytes';
    }

    // Validate format - must be either aura:// URL or base64
    final trimmed = qrCodeData.trim();
    if (trimmed.startsWith('aura://')) {
      // Validate URL format
      if (trimmed.length > _maxUrlLength) {
        return 'QR code URL exceeds maximum length';
      }
      if (!trimmed.startsWith('aura://verify?')) {
        return 'Invalid QR code format: expected aura://verify?data=...';
      }
    } else {
      // Validate base64 format (allow only valid base64 characters)
      final base64Regex = RegExp(r'^[A-Za-z0-9+/=\s]+$');
      if (!base64Regex.hasMatch(trimmed)) {
        return 'Invalid QR code format: not valid base64 or aura:// URL';
      }
    }

    // Check for suspicious patterns
    final lowerData = qrCodeData.toLowerCase();
    if (lowerData.contains('<script') ||
        lowerData.contains('javascript:') ||
        lowerData.contains('data:text/html')) {
      return 'Invalid QR code: contains potentially malicious content';
    }

    return null; // Valid
  }

  Future<void> _onVerifyQRCode(
    VerifyQRCode event,
    Emitter<VerificationState> emit,
  ) async {
    // Security: Validate QR code input before processing
    final validationError = _validateQRCodeInput(event.qrCodeData);
    if (validationError != null) {
      emit(VerificationFailure(
        error: validationError,
        errorCode: 'INVALID_INPUT',
      ));
      return;
    }

    emit(const VerificationLoading(message: 'Verifying credential...'));

    try {
      final result = await _verificationService.verify(
        qrCodeData: event.qrCodeData,
        verifierAddress: event.verifierAddress,
      );

      if (result.isValid) {
        emit(VerificationSuccess(result: result));
      } else {
        emit(VerificationFailure(
          error: result.verificationError ?? 'Verification failed',
          partialResult: result,
        ));
      }
    } catch (e) {
      emit(VerificationFailure(
        error: e.toString(),
        errorCode: 'VERIFICATION_ERROR',
      ));
    }
  }

  void _onResetVerification(
    ResetVerification event,
    Emitter<VerificationState> emit,
  ) {
    emit(const VerificationInitial());
  }

  Future<void> _onCheckAge21(
    CheckAge21 event,
    Emitter<VerificationState> emit,
  ) async {
    // Security: Validate QR code input before processing
    final validationError = _validateQRCodeInput(event.qrCodeData);
    if (validationError != null) {
      emit(VerificationFailure(
        error: validationError,
        errorCode: 'INVALID_INPUT',
      ));
      return;
    }

    emit(const VerificationLoading(message: 'Checking age verification...'));

    try {
      final result = await _verificationService.isAge21Plus(event.qrCodeData);
      emit(AgeCheckResult(
        isOverAge: result.isOver,
        ageThreshold: 21,
        holderDID: result.holderDID,
        verifiedAt: result.verifiedAt,
      ));
    } catch (e) {
      emit(VerificationFailure(
        error: e.toString(),
        errorCode: 'AGE_CHECK_ERROR',
      ));
    }
  }

  Future<void> _onCheckAge18(
    CheckAge18 event,
    Emitter<VerificationState> emit,
  ) async {
    // Security: Validate QR code input before processing
    final validationError = _validateQRCodeInput(event.qrCodeData);
    if (validationError != null) {
      emit(VerificationFailure(
        error: validationError,
        errorCode: 'INVALID_INPUT',
      ));
      return;
    }

    emit(const VerificationLoading(message: 'Checking age verification...'));

    try {
      final result = await _verificationService.isAge18Plus(event.qrCodeData);
      emit(AgeCheckResult(
        isOverAge: result.isOver,
        ageThreshold: 18,
        holderDID: result.holderDID,
        verifiedAt: result.verifiedAt,
      ));
    } catch (e) {
      emit(VerificationFailure(
        error: e.toString(),
        errorCode: 'AGE_CHECK_ERROR',
      ));
    }
  }
}

// Service interface
abstract class VerificationService {
  Future<VerificationResult> verify({
    required String qrCodeData,
    String? verifierAddress,
  });

  Future<AgeCheckResponse> isAge21Plus(String qrCodeData);
  Future<AgeCheckResponse> isAge18Plus(String qrCodeData);
  Future<bool> isVerifiedHuman(String qrCodeData);
}

class AgeCheckResponse {
  final bool isOver;
  final String holderDID;
  final DateTime verifiedAt;

  AgeCheckResponse({
    required this.isOver,
    required this.holderDID,
    required this.verifiedAt,
  });
}
