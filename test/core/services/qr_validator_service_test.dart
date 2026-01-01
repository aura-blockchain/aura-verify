import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_verify_business/core/services/qr_validator_service.dart';

void main() {
  late QRValidatorService validator;

  setUp(() {
    validator = QRValidatorService();
  });

  group('QRValidatorService - Input Validation', () {
    test('should reject null input', () {
      final result = validator.validate(null);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.emptyInput);
    });

    test('should reject empty input', () {
      final result = validator.validate('');
      expect(result.isValid, false);
      expect(result.error, QRValidationError.emptyInput);
    });

    test('should reject input that is too small', () {
      final result = validator.validate('a' * 10);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.tooSmall);
    });

    test('should reject input that exceeds max size', () {
      final result = validator.validate('a' * (10 * 1024 + 1));
      expect(result.isValid, false);
      expect(result.error, QRValidationError.tooLarge);
    });

    test('should reject input with null bytes', () {
      // Input needs to be >= minInputSize (50) to pass size check first
      final input = 'a' * 60 + '\x00' + 'b' * 20;
      final result = validator.validate(input);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidCharacters);
    });

    test('should reject input with control characters', () {
      // Input needs to be >= minInputSize (50) to pass size check first
      final input = 'a' * 60 + '\x01\x02\x03' + 'b' * 20;
      final result = validator.validate(input);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidCharacters);
    });
  });

  group('QRValidatorService - JSON Validation', () {
    test('should reject invalid JSON', () {
      // Create a string that is long enough but not valid JSON
      final longInvalidInput = 'this is definitely not valid json ' * 3;
      final result = validator.validate(longInvalidInput);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidFormat);
    });

    test('should reject non-object JSON', () {
      // Array with enough content to pass size check
      final arrayJson = '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]';
      final result = validator.validate(arrayJson);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidStructure);
    });

    test('should reject JSON with missing required fields', () {
      final data = json.encode({
        'p': 'pres:12345678-abcd-1234-5678',
        'h': 'did:aura:holder123456789',
        // missing 'exp' - add padding to reach min size
        'extra': 'padding data to reach minimum size requirement',
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.missingField);
      expect(result.errorMessage, contains('exp'));
    });

    test('should reject JSON with excessive nesting depth', () {
      Map<String, dynamic> nested = {'value': 'leaf'};
      for (var i = 0; i < 15; i++) {
        nested = {'nested': nested};
      }
      nested['p'] = 'pres:12345678';
      nested['h'] = 'did:aura:holder123';
      nested['exp'] = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      final result = validator.validate(json.encode(nested));
      expect(result.isValid, false);
      expect(result.error, QRValidationError.nestingTooDeep);
    });

    test('should reject JSON with keys that are too long', () {
      final longKey = 'a' * 150;
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        longKey: 'value',
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.keyTooLong);
    });

    test('should reject JSON with values that are too long', () {
      final longValue = 'a' * 3000;
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'extra': longValue,
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.valueTooLong);
    });
  });

  group('QRValidatorService - Field Validation', () {
    test('should reject invalid presentation ID format', () {
      final data = json.encode({
        'p': 'invalid!@#\$%', // Invalid characters
        'h': 'did:aura:holder123',
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidField);
    });

    test('should reject invalid DID format', () {
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'not-a-valid-did', // Missing did: prefix
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidField);
    });

    test('should reject invalid expiration timestamp', () {
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': -1, // Invalid timestamp
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidField);
    });

    test('should reject expired credentials', () {
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.expired);
    });

    test('should reject invalid signature format', () {
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        's': 'too-short', // Signature too short
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
      expect(result.error, QRValidationError.invalidSignature);
    });
  });

  group('QRValidatorService - Valid Inputs', () {
    test('should accept valid JSON credential', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final data = json.encode({
        'p': 'pres:12345678-abcd-1234',
        'h': 'did:aura:holder123456',
        'exp': futureExp,
      });
      final result = validator.validate(data);
      expect(result.isValid, true);
      expect(result.holderDid, 'did:aura:holder123456');
      expect(result.presentationId, 'pres:12345678-abcd-1234');
      expect(result.expiresAt, isNotNull);
    });

    test('should accept valid JSON with optional nonce', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final data = json.encode({
        'p': 'pres:12345678-abcd-1234',
        'h': 'did:aura:holder123456',
        'exp': futureExp,
        'n': 12345,
      });
      final result = validator.validate(data);
      expect(result.isValid, true);
    });

    test('should accept valid JSON with valid signature', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final data = json.encode({
        'p': 'pres:12345678-abcd-1234',
        'h': 'did:aura:holder123456',
        'exp': futureExp,
        's': 'a' * 64, // Valid hex signature length
      });
      final result = validator.validate(data);
      expect(result.isValid, true);
    });

    test('should accept base64-encoded JSON', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final jsonData = json.encode({
        'p': 'pres:12345678-abcd-1234',
        'h': 'did:aura:holder123456',
        'exp': futureExp,
      });
      final base64Data = base64.encode(utf8.encode(jsonData));
      final result = validator.validate(base64Data);
      expect(result.isValid, true);
    });
  });

  group('QRValidatorService - Sanitization', () {
    test('should remove null bytes during sanitization', () {
      final input = 'valid\x00data';
      final sanitized = validator.sanitize(input);
      expect(sanitized, 'validdata');
      expect(sanitized.contains('\x00'), false);
    });

    test('should remove control characters during sanitization', () {
      final input = 'valid\x01\x02\x03data';
      final sanitized = validator.sanitize(input);
      expect(sanitized, 'validdata');
    });

    test('should preserve newlines and tabs', () {
      final input = 'valid\n\tdata';
      final sanitized = validator.sanitize(input);
      expect(sanitized, 'valid\n\tdata');
    });
  });

  group('QRValidatorService - Security Edge Cases', () {
    test('should handle unicode edge cases', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder123',
        'exp': futureExp,
        'extra': 'Hello \u{1F600} World', // Emoji
      });
      final result = validator.validate(data);
      expect(result.isValid, true);
    });

    test('should reject potential command injection in DID', () {
      final futureExp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final data = json.encode({
        'p': 'pres:12345678',
        'h': 'did:aura:holder; rm -rf /', // Injection attempt
        'exp': futureExp,
      });
      final result = validator.validate(data);
      expect(result.isValid, false);
    });
  });
}
