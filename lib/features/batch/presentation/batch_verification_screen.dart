import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/aura_verification_service.dart';
import '../../../core/services/export_service.dart';
import '../../../features/history/domain/verification_record.dart';

class BatchVerificationScreen extends StatefulWidget {
  const BatchVerificationScreen({Key? key}) : super(key: key);

  @override
  State<BatchVerificationScreen> createState() => _BatchVerificationScreenState();
}

class _BatchVerificationScreenState extends State<BatchVerificationScreen> {
  final List<BatchItem> _scannedItems = [];
  bool _isScanning = false;
  bool _isVerifying = false;
  MobileScannerController? _scannerController;
  late final AuraVerificationService _verificationService;
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _verificationService = AuraVerificationService(config: NetworkConfig.mainnet);
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Verification'),
        actions: [
          if (_scannedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClearAll,
              tooltip: 'Clear All',
            ),
          if (_scannedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportResults,
              tooltip: 'Export',
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          if (_scannedItems.isNotEmpty) _buildStatsCard(),

          // Scanner or List
          Expanded(
            child: _isScanning ? _buildScanner() : _buildList(),
          ),

          // Action Button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final total = _scannedItems.length;
    final verified = _scannedItems.where((i) => i.isValid == true).length;
    final failed = _scannedItems.where((i) => i.isValid == false).length;
    final pending = _scannedItems.where((i) => i.isValid == null).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('Total', total.toString(), Colors.blue),
            _buildStat('Verified', verified.toString(), Colors.green),
            _buildStat('Failed', failed.toString(), Colors.red),
            _buildStat('Pending', pending.toString(), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!);
              }
            }
          },
        ),
        // Overlay
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_scannedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items scanned',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start scanning',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _scannedItems.length,
      itemBuilder: (context, index) {
        final item = _scannedItems[index];
        return _buildListItem(item, index);
      },
    );
  }

  Widget _buildListItem(BatchItem item, int index) {
    IconData icon;
    Color color;

    if (item.isValid == null) {
      icon = Icons.hourglass_empty;
      color = Colors.orange;
    } else if (item.isValid!) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.cancel;
      color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text('Item ${index + 1}'),
        subtitle: Text(
          item.qrData.length > 40
              ? '${item.qrData.substring(0, 40)}...'
              : item.qrData,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isValid == null)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!_isScanning && _scannedItems.isNotEmpty) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _verifyAll,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('VERIFY ALL'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleScanning,
                icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                label: Text(_isScanning ? 'STOP SCANNING' : 'SCAN QR CODES'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isScanning ? Colors.red : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScan(String qrData) {
    // Check for duplicates
    if (_scannedItems.any((item) => item.qrData == qrData)) {
      _showSnackBar('Already scanned', Colors.orange);
      return;
    }

    setState(() {
      _scannedItems.add(BatchItem(
        qrData: qrData,
        scannedAt: DateTime.now(),
      ));
    });

    _showSnackBar('Scanned item ${_scannedItems.length}', Colors.green);
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _scannedItems.removeAt(index);
    });
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Remove all scanned items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scannedItems.clear();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAll() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    _showSnackBar('Verifying ${_scannedItems.length} items...', Colors.blue);

    int verified = 0;
    int failed = 0;

    for (int i = 0; i < _scannedItems.length; i++) {
      if (_scannedItems[i].isValid == null) {
        try {
          final result = await _verificationService.verify(
            qrCodeData: _scannedItems[i].qrData,
          );

          setState(() {
            _scannedItems[i].isValid = result.isValid;
            _scannedItems[i].holderDID = result.holderDID;
            _scannedItems[i].verifiedAt = result.verifiedAt;
            if (!result.isValid) {
              _scannedItems[i].errorMessage = result.verificationError ?? 'Verification failed';
            }
          });

          if (result.isValid) {
            verified++;
          } else {
            failed++;
          }
        } on VerificationException catch (e) {
          setState(() {
            _scannedItems[i].isValid = false;
            _scannedItems[i].errorMessage = e.message;
          });
          failed++;
        } catch (e) {
          setState(() {
            _scannedItems[i].isValid = false;
            _scannedItems[i].errorMessage = 'Unexpected error: ${e.toString()}';
          });
          failed++;
        }
      }
    }

    setState(() {
      _isVerifying = false;
    });

    _showSnackBar(
      'Verification complete: $verified verified, $failed failed',
      verified > 0 && failed == 0 ? Colors.green : Colors.orange,
    );
  }

  Future<void> _exportResults() async {
    if (_scannedItems.isEmpty) {
      _showSnackBar('No items to export', Colors.orange);
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
          ],
        ),
      ),
    );

    if (format == null) return;

    _showSnackBar('Exporting results...', Colors.blue);

    try {
      // Convert batch items to verification records
      final records = _scannedItems.map((item) => VerificationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        holderDID: item.holderDID ?? 'Unknown',
        isValid: item.isValid ?? false,
        verifiedAt: item.verifiedAt ?? item.scannedAt,
        verifiedBy: 'batch',
        verifiedByUsername: 'Batch Verification',
        resultType: item.isValid == true
            ? VerificationResultType.success
            : VerificationResultType.failed,
        errorMessage: item.errorMessage,
        networkLatencyMs: 0,
      )).toList();

      File file;
      if (format == 'csv') {
        file = await _exportService.exportHistoryToCsv(records);
      } else {
        file = await _exportService.exportHistoryToJson(records);
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Batch verification results',
      );

      _showSnackBar('Export complete!', Colors.green);
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class BatchItem {
  final String qrData;
  final DateTime scannedAt;
  bool? isValid;
  String? errorMessage;
  String? holderDID;
  DateTime? verifiedAt;

  BatchItem({
    required this.qrData,
    required this.scannedAt,
    this.isValid,
    this.errorMessage,
    this.holderDID,
    this.verifiedAt,
  });
}
