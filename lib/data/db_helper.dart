import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/debt_model.dart';

class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'myr_debt_tracker.db');

    return await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE debts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_name TEXT NOT NULL,
            type TEXT NOT NULL,
            total_amount REAL NOT NULL,
            paid_amount REAL NOT NULL DEFAULT 0.0,
            due_date TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'general',
            installment_group_id TEXT,
            installment_index INTEGER,
            installment_total INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            debt_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            paid_at TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
          )
        ''');

        await _createSettingsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSettingsTable(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE debts ADD COLUMN category TEXT NOT NULL DEFAULT 'general'",
          );
          await db.execute(
            'ALTER TABLE debts ADD COLUMN installment_group_id TEXT',
          );
          await db.execute(
            'ALTER TABLE debts ADD COLUMN installment_index INTEGER',
          );
          await db.execute(
            'ALTER TABLE debts ADD COLUMN installment_total INTEGER',
          );
        }
      },
    );
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<int>> insertDebtsBatch(List<Debt> debts) async {
    final db = await database;
    final ids = <int>[];
    await db.transaction((txn) async {
      for (final debt in debts) {
        final id = await txn.insert('debts', debt.toMap());
        ids.add(id);
      }
    });
    return ids;
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update(
      'debts',
      {
        'person_name': debt.personName,
        'type': debt.type == DebtType.owe ? 'owe' : 'owed',
        'total_amount': debt.totalAmount,
        'due_date': debt.dueDate?.toIso8601String(),
        'note': debt.note,
        'category': debt.category.key,
      },
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<List<Debt>> getDebtsByInstallmentGroup(String groupId) async {
    final db = await database;
    final rows = await db.query(
      'debts',
      where: 'installment_group_id = ?',
      whereArgs: [groupId],
      orderBy: 'installment_index ASC',
    );
    return rows.map((row) => Debt.fromMap(row)).toList();
  }

  Future<int> deleteInstallmentGroup(String groupId) async {
    final db = await database;
    return await db.delete(
      'debts',
      where: 'installment_group_id = ?',
      whereArgs: [groupId],
    );
  }

  Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final rows = await db.query('debts', orderBy: 'created_at DESC');
    return rows.map((row) => Debt.fromMap(row)).toList();
  }

  Future<Debt?> getDebtById(int id) async {
    final db = await database;
    final rows = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Debt.fromMap(rows.first);
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'paid_at DESC',
    );
    return rows.map((row) => DebtPayment.fromMap(row)).toList();
  }

  Future<void> addPayment(DebtPayment payment) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('payments', payment.toMap());
      await txn.rawUpdate(
        'UPDATE debts SET paid_amount = paid_amount + ? WHERE id = ?',
        [payment.amount, payment.debtId],
      );
    });
  }

  Future<void> deletePayment(DebtPayment payment) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments', where: 'id = ?', whereArgs: [payment.id]);
      await txn.rawUpdate(
        'UPDATE debts SET paid_amount = MAX(0.0, paid_amount - ?) WHERE id = ?',
        [payment.amount, payment.debtId],
      );
    });
  }

  Future<Map<String, dynamic>> exportBackupData() async {
    final db = await database;
    final debts = await db.query('debts', orderBy: 'id ASC');
    final payments = await db.query('payments', orderBy: 'id ASC');
    final settingsRows = await db.query('app_settings', orderBy: 'key ASC');

    final settingsMap = <String, String>{};
    for (final row in settingsRows) {
      final key = row['key'];
      final value = row['value'];
      if (key is String && value is String) {
        settingsMap[key] = value;
      }
    }

    return {
      'app': 'myr_debt_tracker',
      'schema_version': 3,
      'app_version': '1.1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'debts': debts,
      'payments': payments,
      'settings': settingsMap,
    };
  }

  Future<({int debtCount, int paymentCount})> importBackupData(
    Map<String, dynamic> data,
  ) async {
    final rawDebts = data['debts'];
    final rawPayments = data['payments'];
    if (rawDebts is! List || rawPayments is! List) {
      throw const FormatException('Backup is missing debts or payments list.');
    }

    final parsedDebts = <({int? oldId, Debt debt})>[];
    for (final item in rawDebts) {
      final map = Map<String, dynamic>.from(item as Map);
      final debt = Debt.fromMap(map);
      parsedDebts.add((oldId: debt.id, debt: debt));
    }

    final parsedPayments = <DebtPayment>[];
    for (final item in rawPayments) {
      final map = Map<String, dynamic>.from(item as Map);
      parsedPayments.add(DebtPayment.fromMap(map));
    }

    final db = await database;
    var restoredPayments = 0;

    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('debts');

      final idMap = <int, int>{};
      for (final entry in parsedDebts) {
        final debtMap = entry.debt.toMap()..remove('id');
        final newId = await txn.insert('debts', debtMap);
        if (entry.oldId != null) {
          idMap[entry.oldId!] = newId;
        }
      }

      for (final payment in parsedPayments) {
        final mappedDebtId = idMap[payment.debtId];
        if (mappedDebtId == null) continue;
        final paymentMap = payment.toMap()
          ..remove('id')
          ..['debt_id'] = mappedDebtId;
        await txn.insert('payments', paymentMap);
        restoredPayments++;
      }

      final rawSettings = data['settings'];
      if (rawSettings is Map) {
        for (final entry in rawSettings.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is String && value is String) {
            await txn.insert(
              'app_settings',
              {'key': key, 'value': value},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });

    return (debtCount: parsedDebts.length, paymentCount: restoredPayments);
  }
}
