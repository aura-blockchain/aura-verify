import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme.dart';
import '../../../core/services/export_service.dart';
import '../domain/verification_record.dart';

/// Screen displaying verification history
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<VerificationHistoryItem> _history = _generateMockHistory();
  String _filterType = 'all';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filterHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportHistory,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(),

          // Filter chips
          _buildFilterChips(),

          // History list
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(filteredHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final successCount = _history.where((h) => h.isValid).length;
    final failureCount = _history.where((h) => !h.isValid).length;
    final todayCount = _history.where((h) =>
      DateUtils.isSameDay(h.verifiedAt, DateTime.now())
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today', todayCount.toString(), Icons.today),
          _buildStatItem('Verified', successCount.toString(), Icons.check_circle,
            color: AuraTheme.successColor),
          _buildStatItem('Failed', failureCount.toString(), Icons.cancel,
            color: AuraTheme.errorColor),
          _buildStatItem('Total', _history.length.toString(), Icons.list),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AuraTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Verified', 'verified'),
          const SizedBox(width: 8),
          _buildFilterChip('Failed', 'failed'),
          const SizedBox(width: 8),
          _buildFilterChip('21+', 'age21'),
          const SizedBox(width: 8),
          _buildFilterChip('18+', 'age18'),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 18),
            label: Text(_dateRange != null ? 'Date Range' : 'Select Dates'),
            onPressed: _selectDateRange,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? type : 'all';
        });
      },
      selectedColor: AuraTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AuraTheme.primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No verification history',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verified credentials will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<VerificationHistoryItem> items) {
    // Group by date
    final grouped = <String, List<VerificationHistoryItem>>{};
    for (final item in items) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.verifiedAt);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateItems = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...dateItems.map((item) => _buildHistoryItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(VerificationHistoryItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isValid
              ? AuraTheme.successColor.withOpacity(0.1)
              : AuraTheme.errorColor.withOpacity(0.1),
          child: Icon(
            item.isValid ? Icons.check : Icons.close,
            color: item.isValid ? AuraTheme.successColor : AuraTheme.errorColor,
          ),
        ),
        title: Row(
          children: [
            Text(
              item.isValid ? 'Verified' : 'Failed',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (item.isOver21) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AuraTheme.successColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '21+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (item.isOver18) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '18+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'DID: ${_truncateDID(item.holderDID)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          DateFormat('HH:mm').format(item.verifiedAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        onTap: () => _showDetailDialog(item),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  String _truncateDID(String did) {
    if (did.length <= 24) return did;
    return '${did.substring(0, 12)}...${did.substring(did.length - 8)}';
  }

  List<VerificationHistoryItem> _filterHistory() {
    var filtered = _history.toList();

    // Apply type filter
    switch (_filterType) {
      case 'verified':
        filtered = filtered.where((h) => h.isValid).toList();
        break;
      case 'failed':
        filtered = filtered.where((h) => !h.isValid).toList();
        break;
      case 'age21':
        filtered = filtered.where((h) => h.isOver21).toList();
        break;
      case 'age18':
        filtered = filtered.where((h) => h.isOver18 && !h.isOver21).toList();
        break;
    }

    // Apply date filter
    if (_dateRange != null) {
      filtered = filtered.where((h) =>
        h.verifiedAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        h.verifiedAt.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Show only verified'),
              onTap: () {
                setState(() => _filterType = 'verified');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Show only failed'),
              onTap: () {
                setState(() => _filterType = 'failed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear filters'),
              onTap: () {
                setState(() {
                  _filterType = 'all';
                  _dateRange = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  void _showDetailDialog(VerificationHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              item.isValid ? Icons.check_circle : Icons.cancel,
              color: item.isValid ? AuraTheme.successColor : AuraTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Text(item.isValid ? 'Verified' : 'Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('DID', item.holderDID),
            _buildDetailRow('Time', DateFormat('yyyy-MM-dd HH:mm:ss').format(item.verifiedAt)),
            _buildDetailRow('Audit ID', item.auditId),
            if (item.isOver21) _buildDetailRow('Age', '21+ Verified'),
            if (item.isOver18 && !item.isOver21) _buildDetailRow('Age', '18+ Verified'),
            if (item.errorMessage != null) _buildDetailRow('Error', item.errorMessage!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No history to export')),
      );
      return;
    }

    // Show export options dialog
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Comma-separated values'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('JavaScript Object Notation'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Report'),
              subtitle: const Text('Compliance report'),
              onTap: () => Navigator.pop(context, 'report'),
            ),
          ],
        ),
      ),
    );

    if (format == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting history...')),
    );

    try {
      final exportService = ExportService();

      // Convert history items to verification records
      final records = _history.map((item) => VerificationRecord(
        id: item.id,
        holderDID: item.holderDID,
        isValid: item.isValid,
        verifiedAt: item.verifiedAt,
        verifiedBy: item.verifiedBy,
        verifiedByUsername: item.verifiedByUsername,
        resultType: item.isValid
            ? VerificationResultType.success
            : VerificationResultType.failed,
        networkLatencyMs: item.networkLatencyMs,
      )).toList();

      File file;
      if (format == 'csv') {
        file = await exportService.exportHistoryToCsv(records);
      } else if (format == 'json') {
        file = await exportService.exportHistoryToJson(records);
      } else {
        // Generate compliance report
        final now = DateTime.now();
        file = await exportService.generateComplianceReport(
          records: records,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        );
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Verification history export',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export complete!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Model for verification history item
class VerificationHistoryItem {
  final String id;
  final String holderDID;
  final DateTime verifiedAt;
  final bool isValid;
  final bool isOver18;
  final bool isOver21;
  final String auditId;
  final String? errorMessage;
  final String verifiedBy;
  final String verifiedByUsername;
  final int networkLatencyMs;

  VerificationHistoryItem({
    required this.id,
    required this.holderDID,
    required this.verifiedAt,
    required this.isValid,
    this.isOver18 = false,
    this.isOver21 = false,
    required this.auditId,
    this.errorMessage,
    this.verifiedBy = 'system',
    this.verifiedByUsername = 'System',
    this.networkLatencyMs = 0,
  });
}

/// Generate mock history for demonstration
List<VerificationHistoryItem> _generateMockHistory() {
  final now = DateTime.now();
  return [
    VerificationHistoryItem(
      id: '1',
      holderDID: 'did:aura:mainnet:abc123def456ghi789',
      verifiedAt: now.subtract(const Duration(minutes: 15)),
      isValid: true,
      isOver21: true,
      isOver18: true,
      auditId: 'audit_001',
    ),
    VerificationHistoryItem(
      id: '2',
      holderDID: 'did:aura:mainnet:xyz987uvw654rst321',
      verifiedAt: now.subtract(const Duration(hours: 1)),
      isValid: true,
      isOver18: true,
      auditId: 'audit_002',
    ),
    VerificationHistoryItem(
      id: '3',
      holderDID: 'did:aura:mainnet:qwe123asd456zxc789',
      verifiedAt: now.subtract(const Duration(hours: 2)),
      isValid: false,
      auditId: 'audit_003',
      errorMessage: 'Credential expired',
    ),
    VerificationHistoryItem(
      id: '4',
      holderDID: 'did:aura:mainnet:poi098lkj765mnb432',
      verifiedAt: now.subtract(const Duration(days: 1, hours: 3)),
      isValid: true,
      isOver21: true,
      isOver18: true,
      auditId: 'audit_004',
    ),
    VerificationHistoryItem(
      id: '5',
      holderDID: 'did:aura:mainnet:fgh456jkl789qrs012',
      verifiedAt: now.subtract(const Duration(days: 1, hours: 5)),
      isValid: false,
      auditId: 'audit_005',
      errorMessage: 'Credential revoked',
    ),
    VerificationHistoryItem(
      id: '6',
      holderDID: 'did:aura:mainnet:tuv234wxy567zab890',
      verifiedAt: now.subtract(const Duration(days: 2)),
      isValid: true,
      isOver18: true,
      auditId: 'audit_006',
    ),
  ];
}
