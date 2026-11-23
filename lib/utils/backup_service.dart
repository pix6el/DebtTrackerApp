import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/db_helper.dart';
import '../models/debt_model.dart';
import 'notification_service.dart';
import 'theme_controller.dart';

class BackupPreview {
  final DateTime? exportedAt;
  final int debtCount;
  final int paymentCount;
  final Map<String, dynamic> rawData;

  const BackupPreview({
    required this.exportedAt,
    required this.debtCount,
    required this.paymentCount,
    required this.rawData,
  });
}

class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.example.myr_debt_tracker/backup',
  );

  Future<String> createBackupJson() async {
    final data = await DbHelper.instance.exportBackupData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> exportToFile() async {
    final jsonString = await createBackupJson();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'myr_debt_backup_$timestamp.json';

    final saved = await _channel.invokeMethod<bool>(
      'saveJsonFile',
      <String, dynamic>{
        'fileName': fileName,
        'content': jsonString,
      },
    );
    return saved == true;
  }

  Future<BackupPreview?> pickBackupFile() async {
    final raw = await _channel.invokeMethod<String>('pickJsonFile');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return parseBackupJson(raw);
  }

  BackupPreview parseBackupJson(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('Selected file is not valid JSON.');
    }

    if (decoded is! Map) {
      throw const FormatException('Invalid backup file format.');
    }

    final data = Map<String, dynamic>.from(decoded);
    if (data['app'] != 'myr_debt_tracker') {
      throw const FormatException(
        'This file is not a MYR Debt Tracker backup.',
      );
    }

    final debtsList = data['debts'];
    final paymentsList = data['payments'];
    if (debtsList is! List || paymentsList is! List) {
      throw const FormatException(
        'Backup file is missing debts or payments data.',
      );
    }

    try {
      for (final item in debtsList) {
        Debt.fromMap(Map<String, dynamic>.from(item as Map));
      }
      for (final item in paymentsList) {
        DebtPayment.fromMap(Map<String, dynamic>.from(item as Map));
      }
    } catch (_) {
      throw const FormatException(
        'Backup file contains invalid or corrupted records.',
      );
    }

    final exportedAtRaw = data['exported_at'];
    final exportedAt =
        exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;

    return BackupPreview(
      exportedAt: exportedAt,
      debtCount: debtsList.length,
      paymentCount: paymentsList.length,
      rawData: data,
    );
  }

  Future<({int debtCount, int paymentCount})> restoreBackup(
    BackupPreview preview,
  ) async {
    final counts = await DbHelper.instance.importBackupData(preview.rawData);
    await ThemeController.instance.load();
    await NotificationService.instance.reloadFromSettings();
    return counts;
  }
}
