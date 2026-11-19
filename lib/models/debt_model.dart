import 'package:flutter/material.dart';

enum DebtType { owe, owed }

enum DebtCategory { general, family, friends, bills, business, other }

extension DebtCategoryX on DebtCategory {
  String get key {
    switch (this) {
      case DebtCategory.general:
        return 'general';
      case DebtCategory.family:
        return 'family';
      case DebtCategory.friends:
        return 'friends';
      case DebtCategory.bills:
        return 'bills';
      case DebtCategory.business:
        return 'business';
      case DebtCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case DebtCategory.general:
        return 'General';
      case DebtCategory.family:
        return 'Family';
      case DebtCategory.friends:
        return 'Friends';
      case DebtCategory.bills:
        return 'Bills';
      case DebtCategory.business:
        return 'Business';
      case DebtCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DebtCategory.general:
        return Icons.label_outline_rounded;
      case DebtCategory.family:
        return Icons.family_restroom_rounded;
      case DebtCategory.friends:
        return Icons.people_outline_rounded;
      case DebtCategory.bills:
        return Icons.receipt_long_outlined;
      case DebtCategory.business:
        return Icons.business_center_outlined;
      case DebtCategory.other:
        return Icons.category_outlined;
    }
  }

  Color get color {
    switch (this) {
      case DebtCategory.general:
        return const Color(0xFF0F766E);
      case DebtCategory.family:
        return const Color(0xFF2563EB);
      case DebtCategory.friends:
        return const Color(0xFF7C3AED);
      case DebtCategory.bills:
        return const Color(0xFFD97706);
      case DebtCategory.business:
        return const Color(0xFF0891B2);
      case DebtCategory.other:
        return const Color(0xFF64748B);
    }
  }

  static DebtCategory fromKey(String? raw) {
    for (final cat in DebtCategory.values) {
      if (cat.key == raw) return cat;
    }
    return DebtCategory.general;
  }
}

class Debt {
  final int? id;
  final String personName;
  final DebtType type; // owe = I owe them, owed = They owe me
  final double totalAmount;
  final double paidAmount;
  final DateTime? dueDate;
  final String note;
  final DateTime createdAt;
  final DebtCategory category;
  final String? installmentGroupId;
  final int? installmentIndex;
  final int? installmentTotal;

  Debt({
    this.id,
    required this.personName,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.dueDate,
    this.note = '',
    required this.createdAt,
    this.category = DebtCategory.general,
    this.installmentGroupId,
    this.installmentIndex,
    this.installmentTotal,
  });

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0.0, totalAmount);

  bool get isSettled => remainingAmount <= 0.009;

  bool get isInstallment =>
      installmentGroupId != null &&
      installmentIndex != null &&
      installmentTotal != null &&
      installmentTotal! > 1;

  String get installmentLabel =>
      isInstallment ? '$installmentIndex/$installmentTotal' : '';

  double get progress =>
      totalAmount == 0 ? 1.0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  bool get isOverdue {
    if (dueDate == null || isSettled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  Debt copyWith({
    int? id,
    String? personName,
    DebtType? type,
    double? totalAmount,
    double? paidAmount,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    DateTime? createdAt,
    DebtCategory? category,
    String? installmentGroupId,
    int? installmentIndex,
    int? installmentTotal,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      installmentGroupId: installmentGroupId ?? this.installmentGroupId,
      installmentIndex: installmentIndex ?? this.installmentIndex,
      installmentTotal: installmentTotal ?? this.installmentTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'type': type == DebtType.owe ? 'owe' : 'owed',
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_date': dueDate?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'category': category.key,
      'installment_group_id': installmentGroupId,
      'installment_index': installmentIndex,
      'installment_total': installmentTotal,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      type: (map['type'] as String) == 'owe' ? DebtType.owe : DebtType.owed,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      category: DebtCategoryX.fromKey(map['category'] as String?),
      installmentGroupId: map['installment_group_id'] as String?,
      installmentIndex: map['installment_index'] as int?,
      installmentTotal: map['installment_total'] as int?,
    );
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paidAt;
  final String note;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paidAt,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'paid_at': paidAt.toIso8601String(),
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paidAt: DateTime.parse(map['paid_at'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}
