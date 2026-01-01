import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:aura_verify_business/features/verification/bloc/verification_bloc.dart'
    as bloc;

// Mock VerificationService
class MockVerificationService implements bloc.VerificationService {
  bloc.VerificationResult? mockResult;
  bloc.AgeCheckResponse? mockAgeResponse;
  Exception? mockException;

  @override
  Future<bloc.VerificationResult> verify({
    required String qrCodeData,
    String? verifierAddress,
  }) async {
    if (mockException != null) throw mockException!;
    return mockResult!;
  }

  @override
  Future<bloc.AgeCheckResponse> isAge21Plus(String qrCodeData) async {
    if (mockException != null) throw mockException!;
    return mockAgeResponse!;
  }

  @override
  Future<bloc.AgeCheckResponse> isAge18Plus(String qrCodeData) async {
    if (mockException != null) throw mockException!;
    return mockAgeResponse!;
  }

  @override
  Future<bool> isVerifiedHuman(String qrCodeData) async {
    return true;
  }
}

void main() {
  late MockVerificationService mockService;

  setUp(() {
    mockService = MockVerificationService();
  });

  group('VerificationBloc - Initial State', () {
    test('initial state is VerificationInitial', () {
      final b = bloc.VerificationBloc(verificationService: mockService);
      expect(b.state, isA<bloc.VerificationInitial>());
      b.close();
    });
  });

  group('VerificationBloc - Input Validation', () {
    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure when QR code is empty',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) => b.add(const bloc.VerifyQRCode(qrCodeData: '')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('empty'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure when QR code exceeds max length',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) => b.add(bloc.VerifyQRCode(qrCodeData: 'a' * 10000)),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('maximum'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure when QR code contains null bytes',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) => b.add(const bloc.VerifyQRCode(qrCodeData: 'test\x00data')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('null bytes'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure when QR code contains invalid characters (script tags)',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      // Raw HTML/script tags fail base64 validation as they contain < and > chars
      act: (b) =>
          b.add(const bloc.VerifyQRCode(qrCodeData: '<script>alert(1)</script>')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('not valid base64'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure when QR code contains javascript: URL',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) =>
          b.add(const bloc.VerifyQRCode(qrCodeData: 'javascript:alert(1)')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('not valid base64'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits VerificationFailure for invalid aura:// URL format',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) => b.add(const bloc.VerifyQRCode(qrCodeData: 'aura://invalid')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('aura://verify'))
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );
  });

  group('VerificationBloc - Successful Verification', () {
    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits Loading then Success for valid verification',
      build: () {
        mockService.mockResult = bloc.VerificationResult(
          isValid: true,
          holderDID: 'did:aura:test123',
          verifiedAt: DateTime.now(),
          vcDetails: [
            bloc.VCDetail(
              vcId: 'vc:test:001',
              vcType: bloc.VCType.verifiedHuman,
              status: bloc.VCStatus.active,
              isValid: true,
              isExpired: false,
              isRevoked: false,
            ),
          ],
          attributes: bloc.DiscloseableAttributes(
            fullName: 'Test User',
            isOver18: true,
            isOver21: true,
          ),
          auditId: 'audit-123',
          networkLatencyMs: 50,
          method: bloc.VerificationMethod.online,
        );
        return bloc.VerificationBloc(verificationService: mockService);
      },
      act: (b) => b.add(const bloc.VerifyQRCode(
        qrCodeData: 'aura://verify?data=validbase64data',
      )),
      expect: () => [
        isA<bloc.VerificationLoading>(),
        isA<bloc.VerificationSuccess>()
            .having((s) => s.result.isValid, 'isValid', true)
            .having((s) => s.result.holderDID, 'holderDID', 'did:aura:test123'),
      ],
    );
  });

  group('VerificationBloc - Failed Verification', () {
    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits Loading then Failure for invalid verification',
      build: () {
        mockService.mockResult = bloc.VerificationResult(
          isValid: false,
          holderDID: 'did:aura:test123',
          verifiedAt: DateTime.now(),
          vcDetails: [],
          attributes: bloc.DiscloseableAttributes(),
          verificationError: 'Credential has been revoked',
          auditId: 'audit-456',
          networkLatencyMs: 45,
          method: bloc.VerificationMethod.online,
        );
        return bloc.VerificationBloc(verificationService: mockService);
      },
      act: (b) => b.add(const bloc.VerifyQRCode(
        qrCodeData: 'aura://verify?data=revokedcredential',
      )),
      expect: () => [
        isA<bloc.VerificationLoading>(),
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', 'Credential has been revoked')
            .having((f) => f.partialResult, 'partialResult', isNotNull),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits Failure when service throws exception',
      build: () {
        mockService.mockException = Exception('Network timeout');
        return bloc.VerificationBloc(verificationService: mockService);
      },
      act: (b) => b.add(const bloc.VerifyQRCode(
        qrCodeData: 'aura://verify?data=validdata',
      )),
      expect: () => [
        isA<bloc.VerificationLoading>(),
        isA<bloc.VerificationFailure>()
            .having((f) => f.error, 'error', contains('Network timeout'))
            .having((f) => f.errorCode, 'errorCode', 'VERIFICATION_ERROR'),
      ],
    );
  });

  group('VerificationBloc - Age Verification', () {
    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits AgeCheckResult for age 21+ check',
      build: () {
        mockService.mockAgeResponse = bloc.AgeCheckResponse(
          isOver: true,
          holderDID: 'did:aura:adult123',
          verifiedAt: DateTime.now(),
        );
        return bloc.VerificationBloc(verificationService: mockService);
      },
      act: (b) => b.add(const bloc.CheckAge21(
        qrCodeData: 'aura://verify?data=validdata',
      )),
      expect: () => [
        isA<bloc.VerificationLoading>(),
        isA<bloc.AgeCheckResult>()
            .having((r) => r.isOverAge, 'isOverAge', true)
            .having((r) => r.ageThreshold, 'ageThreshold', 21),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'emits AgeCheckResult for age 18+ check',
      build: () {
        mockService.mockAgeResponse = bloc.AgeCheckResponse(
          isOver: true,
          holderDID: 'did:aura:adult123',
          verifiedAt: DateTime.now(),
        );
        return bloc.VerificationBloc(verificationService: mockService);
      },
      act: (b) => b.add(const bloc.CheckAge18(
        qrCodeData: 'aura://verify?data=validdata',
      )),
      expect: () => [
        isA<bloc.VerificationLoading>(),
        isA<bloc.AgeCheckResult>()
            .having((r) => r.isOverAge, 'isOverAge', true)
            .having((r) => r.ageThreshold, 'ageThreshold', 18),
      ],
    );

    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'validates input before age check',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      act: (b) => b.add(const bloc.CheckAge21(qrCodeData: '')),
      expect: () => [
        isA<bloc.VerificationFailure>()
            .having((f) => f.errorCode, 'errorCode', 'INVALID_INPUT'),
      ],
    );
  });

  group('VerificationBloc - Reset', () {
    blocTest<bloc.VerificationBloc, bloc.VerificationState>(
      'resets to initial state',
      build: () => bloc.VerificationBloc(verificationService: mockService),
      seed: () => bloc.VerificationFailure(error: 'Previous error'),
      act: (b) => b.add(const bloc.ResetVerification()),
      expect: () => [isA<bloc.VerificationInitial>()],
    );
  });

  group('VerificationResult - JSON Parsing', () {
    test('parses valid JSON correctly', () {
      final json = {
        'is_valid': true,
        'holder_did': 'did:aura:test',
        'verified_at': DateTime.now().toIso8601String(),
        'vc_details': [
          {
            'vc_id': 'vc:001',
            'vc_type': 1,
            'status': 2,
            'is_valid': true,
            'is_expired': false,
            'is_revoked': false,
          }
        ],
        'attributes': {
          'full_name': 'John Doe',
          'age': 25,
          'is_over_18': true,
          'is_over_21': true,
        },
        'audit_id': 'audit-789',
        'network_latency_ms': 42,
        'verification_method': 'online',
      };

      final result = bloc.VerificationResult.fromJson(json);

      expect(result.isValid, true);
      expect(result.holderDID, 'did:aura:test');
      expect(result.vcDetails.length, 1);
      expect(result.vcDetails.first.vcType, bloc.VCType.verifiedHuman);
      expect(result.attributes.fullName, 'John Doe');
      expect(result.attributes.age, 25);
      expect(result.attributes.isOver18, true);
      expect(result.networkLatencyMs, 42);
      expect(result.method, bloc.VerificationMethod.online);
    });

    test('handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final result = bloc.VerificationResult.fromJson(json);

      expect(result.isValid, false);
      expect(result.holderDID, '');
      expect(result.vcDetails, isEmpty);
    });
  });

  group('VCType - fromCode', () {
    test('returns correct type for known codes', () {
      expect(bloc.VCType.fromCode(0), bloc.VCType.unspecified);
      expect(bloc.VCType.fromCode(1), bloc.VCType.verifiedHuman);
      expect(bloc.VCType.fromCode(2), bloc.VCType.ageOver18);
      expect(bloc.VCType.fromCode(3), bloc.VCType.ageOver21);
      expect(bloc.VCType.fromCode(6), bloc.VCType.kycVerification);
    });

    test('returns unspecified for unknown codes', () {
      expect(bloc.VCType.fromCode(999), bloc.VCType.unspecified);
    });
  });

  group('VCStatus - fromCode', () {
    test('returns correct status for known codes', () {
      expect(bloc.VCStatus.fromCode(0), bloc.VCStatus.unspecified);
      expect(bloc.VCStatus.fromCode(1), bloc.VCStatus.pending);
      expect(bloc.VCStatus.fromCode(2), bloc.VCStatus.active);
      expect(bloc.VCStatus.fromCode(3), bloc.VCStatus.revoked);
      expect(bloc.VCStatus.fromCode(4), bloc.VCStatus.expired);
    });

    test('returns unspecified for unknown codes', () {
      expect(bloc.VCStatus.fromCode(999), bloc.VCStatus.unspecified);
    });
  });
}
