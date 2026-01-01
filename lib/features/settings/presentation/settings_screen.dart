import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../core/services/offline_cache_service.dart';

/// Settings screen for Aura Verify Business app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  String _selectedNetwork = 'mainnet';
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoScan = true;
  bool _offlineMode = false;
  int _cacheRetentionDays = 7;
  String _defaultAgeCheck = '21';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Network Settings
          _buildSectionHeader('Network'),
          _buildNetworkSelector(),
          _buildSwitchTile(
            title: 'Offline Mode',
            subtitle: 'Use cached data when network is unavailable',
            icon: Icons.wifi_off,
            value: _offlineMode,
            onChanged: (value) => setState(() => _offlineMode = value),
          ),
          const Divider(),

          // Verification Settings
          _buildSectionHeader('Verification'),
          _buildAgeCheckSelector(),
          _buildSwitchTile(
            title: 'Auto-Scan',
            subtitle: 'Automatically start scanning after verification',
            icon: Icons.qr_code_scanner,
            value: _autoScan,
            onChanged: (value) => setState(() => _autoScan = value),
          ),
          const Divider(),

          // Feedback Settings
          _buildSectionHeader('Feedback'),
          _buildSwitchTile(
            title: 'Sound',
            subtitle: 'Play sound on verification result',
            icon: Icons.volume_up,
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate on verification result',
            icon: Icons.vibration,
            value: _vibrationEnabled,
            onChanged: (value) => setState(() => _vibrationEnabled = value),
          ),
          const Divider(),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy'),
          _buildCacheRetentionSelector(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear History'),
            subtitle: const Text('Remove all verification history'),
            onTap: _confirmClearHistory,
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Cache'),
            subtitle: const Text('Update offline verification data'),
            onTap: _syncCache,
          ),
          const Divider(),

          // Business Settings
          _buildSectionHeader('Business'),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business Profile'),
            subtitle: const Text('Configure your business information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openBusinessProfile,
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Staff Accounts'),
            subtitle: const Text('Manage staff access'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openStaffAccounts,
          ),
          ListTile(
            leading: const Icon(Icons.integration_instructions),
            title: const Text('Integrations'),
            subtitle: const Text('POS systems, webhooks, and more'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openIntegrations,
          ),
          const Divider(),

          // About
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: _openTerms,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: _openPrivacy,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openHelp,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AuraTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AuraTheme.primaryColor,
    );
  }

  Widget _buildNetworkSelector() {
    return ListTile(
      leading: const Icon(Icons.cloud),
      title: const Text('Network'),
      subtitle: Text(_getNetworkDisplayName(_selectedNetwork)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showNetworkDialog(),
    );
  }

  String _getNetworkDisplayName(String network) {
    switch (network) {
      case 'mainnet':
        return 'Aura Mainnet (Production)';
      case 'testnet':
        return 'Aura Testnet (Testing)';
      case 'local':
        return 'Local Development';
      default:
        return network;
    }
  }

  void _showNetworkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNetworkOption('mainnet', 'Aura Mainnet', 'Production network'),
            _buildNetworkOption('testnet', 'Aura Testnet', 'Testing network'),
            _buildNetworkOption('local', 'Local', 'Development only'),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOption(String value, String title, String subtitle) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: _selectedNetwork,
      onChanged: (newValue) {
        setState(() => _selectedNetwork = newValue!);
        Navigator.pop(context);
      },
      activeColor: AuraTheme.primaryColor,
    );
  }

  Widget _buildAgeCheckSelector() {
    return ListTile(
      leading: const Icon(Icons.cake),
      title: const Text('Default Age Verification'),
      subtitle: Text(_defaultAgeCheck == '21' ? '21+ (Alcohol/Cannabis)' : '18+ (Adult)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAgeCheckDialog(),
    );
  }

  void _showAgeCheckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Age Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('21+'),
              subtitle: const Text('Alcohol, cannabis, gambling'),
              value: '21',
              groupValue: _defaultAgeCheck,
              onChanged: (value) {
                setState(() => _defaultAgeCheck = value!);
                Navigator.pop(context);
              },
              activeColor: AuraTheme.primaryColor,
            ),
            RadioListTile<String>(
              title: const Text('18+'),
              subtitle: const Text('Adult content, tobacco'),
              value: '18',
              groupValue: _defaultAgeCheck,
              onChanged: (value) {
                setState(() => _defaultAgeCheck = value!);
                Navigator.pop(context);
              },
              activeColor: AuraTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheRetentionSelector() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('History Retention'),
      subtitle: Text('$_cacheRetentionDays days'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showRetentionDialog(),
    );
  }

  void _showRetentionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Retention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [7, 14, 30, 90, 365].map((days) {
            return RadioListTile<int>(
              title: Text('$days days'),
              value: days,
              groupValue: _cacheRetentionDays,
              onChanged: (value) {
                setState(() => _cacheRetentionDays = value!);
                Navigator.pop(context);
              },
              activeColor: AuraTheme.primaryColor,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all verification history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            style: TextButton.styleFrom(
              foregroundColor: AuraTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    try {
      final cacheService = OfflineCacheService();
      await cacheService.clearAllCachedCredentials();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncCache() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing cache...')),
    );

    try {
      final cacheService = OfflineCacheService();
      await cacheService.syncWithNetwork();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openBusinessProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business profile coming soon')),
    );
  }

  void _openStaffAccounts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff accounts coming soon')),
    );
  }

  void _openIntegrations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Integrations coming soon')),
    );
  }

  Future<void> _openTerms() async {
    final url = Uri.parse('https://aura.network/terms');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Terms of Service')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _openPrivacy() async {
    final url = Uri.parse('https://aura.network/privacy');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Privacy Policy')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _openHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon')),
    );
  }
}
