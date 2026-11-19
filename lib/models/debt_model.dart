enum DebtType { owe, owed }

class Debt {
  final int? id;
  final String personName;
  final DebtType type; // owe = I owe them, owed = They owe me
  final double totalAmount;
  final double paidAmount;
  final DateTime? dueDate;
  final String note;
  final DateTime createdAt;

  Debt({
    this.id,
    required this.personName,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.dueDate,
    this.note = '',
    required this.createdAt,
  });

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0.0, totalAmount);

  bool get isSettled => remainingAmount <= 0.009;

  double get progress =>
      totalAmount == 0 ? 1.0 : (paidAmount / totalAmount).clamp(0.0, 1.0);

  bool get isOverdue {
    if (dueDate == null || isSettled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
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
