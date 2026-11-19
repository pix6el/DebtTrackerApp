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
      version: 2,
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
            created_at TEXT NOT NULL
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
      },
      where: 'id = ?',
      whereArgs: [debt.id],
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
}
