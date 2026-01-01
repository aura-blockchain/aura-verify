import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/widgets/aura_app_bar.dart';
import 'widgets/verification_badge.dart';
import 'widgets/attribute_card.dart';

/// Verification Result Screen
class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> verificationData;

  const ResultScreen({
    Key? key,
    required this.verificationData,
  }) : super(key: key);

  bool get isSuccess => verificationData['success'] == true;
  bool get isOver21 => verificationData['over21'] == true;
  bool get isOver18 => verificationData['over18'] == true;
  int? get age => verificationData['age'] as int?;

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: const AuraAppBar(
        title: 'Verification Result',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isPortrait ? 24.0 : 16.0),
            child: isPortrait
                ? _buildPortraitLayout(context)
                : _buildLandscapeLayout(context),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVerificationBadge(context),
        const SizedBox(height: 32),
        if (isSuccess) ...[
          _buildAgeVerificationStatus(context),
          const SizedBox(height: 24),
          _buildAttributesSection(context),
        ] else ...[
          _buildErrorMessage(context),
        ],
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildVerificationBadge(context),
              const SizedBox(height: 16),
              if (isSuccess) _buildAgeVerificationStatus(context),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: isSuccess
              ? _buildAttributesSection(context)
              : _buildErrorMessage(context),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge(BuildContext context) {
    return VerificationBadge(
      isSuccess: isSuccess,
      title: isSuccess ? 'Verified' : 'Verification Failed',
      subtitle: isSuccess
          ? 'Credential is valid'
          : verificationData['error'] ?? 'Invalid credential',
    );
  }

  Widget _buildAgeVerificationStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver21
              ? [AuraTheme.successGreen, AuraTheme.successGreenDark]
              : isOver18
                  ? [AuraTheme.warningOrange, AuraTheme.warningOrangeDark]
                  : [AuraTheme.errorRed, AuraTheme.errorRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
        boxShadow: [
          BoxShadow(
            color: (isOver21
                    ? AuraTheme.successGreen
                    : isOver18
                        ? AuraTheme.warningOrange
                        : AuraTheme.errorRed)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isOver21
                ? Icons.verified
                : isOver18
                    ? Icons.check_circle
                    : Icons.cancel,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: 16),
          if (age != null)
            Text(
              'Age: $age',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          const SizedBox(height: 8),
          Text(
            isOver21
                ? '21+ VERIFIED'
                : isOver18
                    ? '18+ VERIFIED'
                    : 'UNDER 18',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isOver21
                ? 'Allowed for all age-restricted purchases'
                : isOver18
                    ? 'Allowed for 18+ purchases only'
                    : 'Not allowed for age-restricted purchases',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(BuildContext context) {
    final attributes = verificationData['attributes'] as Map<String, dynamic>?;

    if (attributes == null || attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credential Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Display key attributes
        if (attributes['firstName'] != null || attributes['lastName'] != null)
          AttributeCard(
            icon: Icons.person,
            label: 'Name',
            value: '${attributes['firstName'] ?? ''} ${attributes['lastName'] ?? ''}'.trim(),
          ),

        if (attributes['dateOfBirth'] != null)
          AttributeCard(
            icon: Icons.cake,
            label: 'Date of Birth',
            value: _formatDate(attributes['dateOfBirth']),
          ),

        if (attributes['credentialId'] != null)
          AttributeCard(
            icon: Icons.fingerprint,
            label: 'Credential ID',
            value: attributes['credentialId'],
          ),

        if (attributes['issuedBy'] != null)
          AttributeCard(
            icon: Icons.business,
            label: 'Issued By',
            value: attributes['issuedBy'],
          ),

        if (verificationData['issuedDate'] != null)
          AttributeCard(
            icon: Icons.calendar_today,
            label: 'Issued Date',
            value: _formatDate(verificationData['issuedDate']),
          ),

        if (attributes['expiresAt'] != null)
          AttributeCard(
            icon: Icons.event,
            label: 'Expires',
            value: _formatDate(attributes['expiresAt']),
            isWarning: _isExpiringSoon(attributes['expiresAt']),
          ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraTheme.errorRedLight.withOpacity(0.1),
        border: Border.all(color: AuraTheme.errorRed, width: 2),
        borderRadius: BorderRadius.circular(AppConfig.borderRadiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AuraTheme.errorRed, size: 28),
              const SizedBox(width: 12),
              Text(
                'Error Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AuraTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            verificationData['error'] ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Please ensure:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('The QR code is a valid Aura credential'),
          _buildBulletPoint('The credential has not been revoked'),
          _buildBulletPoint('You have a stable internet connection'),
          _buildBulletPoint('The credential has not expired'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.history),
              icon: const Icon(Icons.history),
              label: const Text('View History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'N/A';

      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }

      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

  bool _isExpiringSoon(dynamic expiresAt) {
    try {
      if (expiresAt == null) return false;

      DateTime expiry;
      if (expiresAt is String) {
        expiry = DateTime.parse(expiresAt);
      } else if (expiresAt is DateTime) {
        expiry = expiresAt;
      } else {
        return false;
      }

      final daysUntilExpiry = expiry.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    } catch (e) {
      return false;
    }
  }
}
