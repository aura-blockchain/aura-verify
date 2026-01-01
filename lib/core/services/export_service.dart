import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../features/history/domain/verification_record.dart';
import '../../features/audit/domain/audit_entry.dart';

/// Service for exporting data to various formats
class ExportService {
  /// Export verification history to CSV
  Future<File> exportHistoryToCsv(List<VerificationRecord> records) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'ID,Holder DID,Is Valid,Verified At,Verified By,Result Type,Error Message,Latency (ms)',
    );

    // CSV Data
    for (final record in records) {
      buffer.writeln(
        '${_escapeCsv(record.id)},'
        '${_escapeCsv(record.holderDID)},'
        '${record.isValid},'
        '${_formatDateTime(record.verifiedAt)},'
        '${_escapeCsv(record.verifiedByUsername)},'
        '${_escapeCsv(record.resultType.displayName)},'
        '${_escapeCsv(record.errorMessage ?? '')},'
        '${record.networkLatencyMs}',
      );
    }

    return _saveToFile(buffer.toString(), 'verification_history', 'csv');
  }

  /// Export verification history to JSON
  Future<File> exportHistoryToJson(List<VerificationRecord> records) async {
    final jsonData = {
      'export_date': DateTime.now().toIso8601String(),
      'record_count': records.length,
      'records': records.map((r) => r.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    return _saveToFile(jsonString, 'verification_history', 'json');
  }

  /// Export audit log to CSV
  Future<File> exportAuditLogToCsv(List<AuditEntry> entries) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
      'ID,User,Action,Description,Timestamp,IP Address,Device Info',
    );

    // CSV Data
    for (final entry in entries) {
      buffer.writeln(
        '${_escapeCsv(entry.id)},'
        '${_escapeCsv(entry.username)},'
        '${_escapeCsv(entry.action.displayName)},'
        '${_escapeCsv(entry.description)},'
        '${_formatDateTime(entry.timestamp)},'
        '${_escapeCsv(entry.ipAddress ?? '')},'
        '${_escapeCsv(entry.deviceInfo ?? '')}',
      );
    }

    return _saveToFile(buffer.toString(), 'audit_log', 'csv');
  }

  /// Export audit log to JSON
  Future<File> exportAuditLogToJson(List<AuditEntry> entries) async {
    final jsonData = {
      'export_date': DateTime.now().toIso8601String(),
      'entry_count': entries.length,
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    return _saveToFile(jsonString, 'audit_log', 'json');
  }

  /// Generate compliance report
  Future<File> generateComplianceReport({
    required List<VerificationRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final buffer = StringBuffer();

    // Report Header
    buffer.writeln('AURA VERIFICATION COMPLIANCE REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('Report Generated: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('Period: ${_formatDate(startDate)} to ${_formatDate(endDate)}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Summary Statistics
    final total = records.length;
    final successful = records.where((r) => r.isValid).length;
    final failed = records.where((r) => !r.isValid).length;
    final successRate = total > 0 ? (successful / total * 100).toStringAsFixed(2) : '0.00';

    buffer.writeln('SUMMARY STATISTICS');
    buffer.writeln('-' * 60);
    buffer.writeln('Total Verifications: $total');
    buffer.writeln('Successful: $successful');
    buffer.writeln('Failed: $failed');
    buffer.writeln('Success Rate: $successRate%');
    buffer.writeln();

    // Average Latency
    if (records.isNotEmpty) {
      final avgLatency = records
          .map((r) => r.networkLatencyMs)
          .reduce((a, b) => a + b) /
          records.length;
      buffer.writeln('Average Network Latency: ${avgLatency.toStringAsFixed(2)}ms');
    }
    buffer.writeln();

    // Detailed Records
    buffer.writeln('DETAILED RECORDS');
    buffer.writeln('-' * 60);
    for (final record in records) {
      buffer.writeln('Timestamp: ${_formatDateTime(record.verifiedAt)}');
      buffer.writeln('DID: ${record.holderDID}');
      buffer.writeln('Result: ${record.isValid ? 'SUCCESS' : 'FAILED'}');
      buffer.writeln('Verified By: ${record.verifiedByUsername}');
      if (record.errorMessage != null) {
        buffer.writeln('Error: ${record.errorMessage}');
      }
      buffer.writeln('-' * 60);
    }

    return _saveToFile(buffer.toString(), 'compliance_report', 'txt');
  }

  Future<File> _saveToFile(String content, String baseName, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${baseName}_$timestamp.$extension';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content);

    return file;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
