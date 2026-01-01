import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/aura_app_bar.dart';
import '../../../core/services/qr_validator_service.dart';
import 'scanner_overlay.dart';

/// QR Code Scanner Screen
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  /// Security: QR validator for input sanitization and format validation
  final QRValidatorService _validator = QRValidatorService();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (_isProcessing) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Security: Sanitize and validate QR code data before processing
    final rawQrData = barcode.rawValue!;
    final sanitizedData = _validator.sanitize(rawQrData);
    final validationResult = _validator.validate(sanitizedData);

    // Handle validation failure
    if (!validationResult.isValid) {
      _showValidationError(validationResult);
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Navigate to result screen with the validated data
    context.push(
      AppRoutes.result,
      extra: _parseValidatedQRData(validationResult),
    ).then((_) {
      // Reset processing flag when returning
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  /// Show validation error to user
  void _showValidationError(QRValidationResult result) {
    final errorMessage = _getErrorMessage(result.error!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Get user-friendly error message for validation error
  String _getErrorMessage(QRValidationError error) {
    switch (error) {
      case QRValidationError.emptyInput:
        return 'QR code is empty';
      case QRValidationError.tooLarge:
        return 'QR code data is too large';
      case QRValidationError.tooSmall:
        return 'Not a valid Aura credential';
      case QRValidationError.invalidCharacters:
        return 'QR code contains invalid data';
      case QRValidationError.invalidFormat:
        return 'Invalid QR code format';
      case QRValidationError.invalidStructure:
        return 'Invalid credential structure';
      case QRValidationError.nestingTooDeep:
        return 'Invalid credential format';
      case QRValidationError.keyTooLong:
      case QRValidationError.valueTooLong:
        return 'Credential data exceeds limits';
      case QRValidationError.missingField:
        return 'Incomplete credential data';
      case QRValidationError.invalidField:
        return 'Invalid credential field';
      case QRValidationError.invalidSignature:
        return 'Invalid credential signature';
      case QRValidationError.expired:
        return 'Credential has expired';
    }
  }

  /// Parse validated QR data into result format
  /// Security: Only called after validation passes
  Map<String, dynamic> _parseValidatedQRData(QRValidationResult validationResult) {
    final now = DateTime.now();
    final parsedData = validationResult.parsedData!;

    // Extract attributes from validated data
    final attributes = parsedData['a'] as Map<String, dynamic>? ?? {};

    // Extract age-related claims if present
    final isOver18 = attributes['over18'] as bool? ?? false;
    final isOver21 = attributes['over21'] as bool? ?? false;

    return {
      'success': true,
      'qrData': validationResult.sanitizedData,
      'holderDid': validationResult.holderDid,
      'presentationId': validationResult.presentationId,
      'credentialType': parsedData['t'] ?? 'AuraCredential',
      'issuer': parsedData['i'] ?? 'Unknown Issuer',
      'issuedDate': parsedData['iat'] != null
          ? DateTime.fromMillisecondsSinceEpoch((parsedData['iat'] as int) * 1000).toIso8601String()
          : now.subtract(const Duration(days: 365)).toIso8601String(),
      'verified': false, // Will be set by verification service
      'over18': isOver18,
      'over21': isOver21,
      'expiresAt': validationResult.expiresAt?.toIso8601String(),
      'attributes': attributes,
      'verificationTime': now.toIso8601String(),
      // Pass nonce for replay protection
      'nonce': parsedData['n'],
    };
  }

  /// Legacy parse method - kept for backwards compatibility
  /// @deprecated Use _parseValidatedQRData instead
  Map<String, dynamic> _parseQRData(String qrData) {
    // Security: This method is deprecated - validation should happen first
    // Left for backwards compatibility with any code paths that might use it
    final validationResult = _validator.validate(qrData);

    if (!validationResult.isValid) {
      return {
        'success': false,
        'error': validationResult.errorMessage ?? 'Invalid QR code format',
        'qrData': _validator.sanitize(qrData),
      };
    }

    return _parseValidatedQRData(validationResult);
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: const AuraAppBar(
        title: 'Aura Verify Business',
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetect,
          ),

          // Scanner Overlay
          const ScannerOverlay(),

          // Instructions
          Positioned(
            left: 0,
            right: 0,
            bottom: isPortrait ? 80 : 40,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan Aura Credential',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position the QR code within the frame',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Flash toggle button
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: _controller.torchState,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ),

          // Camera toggle button (if multiple cameras available)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: () => _controller.switchCamera(),
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation or action buttons
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              color: AuraTheme.primaryPurple,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    context,
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => context.push(AppRoutes.history),
                  ),
                  _buildNavButton(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan',
                    onTap: null, // Current screen
                    isActive: true,
                  ),
                  _buildNavButton(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AuraTheme.secondaryTealLight : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AuraTheme.secondaryTealLight : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
