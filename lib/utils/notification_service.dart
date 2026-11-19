import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../data/db_helper.dart';
import '../models/debt_model.dart';
import 'formatters.dart';

enum ReminderTiming { both, dayBefore, onDueDate }

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const String _enabledKey = 'reminders_enabled';
  static const String _timingKey = 'reminder_timing';
  static const String _channelId = 'debt_due_reminders';
  static const String _channelName = 'Debt Due Date Reminders';
  static const String _channelDescription =
      'Offline reminders for upcoming debt due dates';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final ValueNotifier<ReminderTiming> timing =
      ValueNotifier<ReminderTiming>(ReminderTiming.both);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      return;
    }

    final savedEnabled = await DbHelper.instance.getSetting(_enabledKey);
    enabled.value = savedEnabled != 'false';

    final savedTiming = await DbHelper.instance.getSetting(_timingKey);
    timing.value = _timingFromString(savedTiming);

    if (enabled.value) {
      await requestPermission();
      await rescheduleAllDebts();
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await DbHelper.instance.setSetting(_enabledKey, value ? 'true' : 'false');

    if (value) {
      await requestPermission();
      await rescheduleAllDebts();
    } else {
      await cancelAll();
    }
  }

  Future<void> setTiming(ReminderTiming value) async {
    timing.value = value;
    await DbHelper.instance.setSetting(_timingKey, _timingToString(value));

    if (enabled.value) {
      await rescheduleAllDebts();
    }
  }

  Future<void> syncDebtReminder(Debt debt) async {
    if (!_initialized || debt.id == null) return;
    await cancelDebtReminders(debt.id!);

    if (!enabled.value || debt.isSettled || debt.dueDate == null) {
      return;
    }

    final due = debt.dueDate!;
    final isOwe = debt.type == DebtType.owe;
    final formattedAmount = Formatters.myr(debt.remainingAmount);
    final formattedDue = Formatters.date(due);

    // 1 day before at 9:00 AM local time
    if (timing.value == ReminderTiming.both ||
        timing.value == ReminderTiming.dayBefore) {
      final dayBefore = DateTime(due.year, due.month, due.day - 1, 9, 0);
      await _scheduleOne(
        id: _dayBeforeId(debt.id!),
        scheduledLocalTime: dayBefore,
        title: isOwe ? 'Payment Due Tomorrow' : 'Collection Due Tomorrow',
        body: isOwe
            ? 'You owe ${debt.personName} $formattedAmount (due $formattedDue).'
            : '${debt.personName} owes you $formattedAmount (due $formattedDue).',
      );
    }

    // On due date at 9:00 AM local time
    if (timing.value == ReminderTiming.both ||
        timing.value == ReminderTiming.onDueDate) {
      final onDueDay = DateTime(due.year, due.month, due.day, 9, 0);
      await _scheduleOne(
        id: _onDueDateId(debt.id!),
        scheduledLocalTime: onDueDay,
        title: isOwe ? 'Payment Due Today' : 'Collection Due Today',
        body: isOwe
            ? 'You owe ${debt.personName} $formattedAmount today.'
            : '${debt.personName} owes you $formattedAmount today.',
      );
    }
  }

  Future<void> cancelDebtReminders(int debtId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_dayBeforeId(debtId));
      await _plugin.cancel(_onDueDateId(debtId));
    } catch (_) {}
  }

  Future<void> rescheduleAllDebts() async {
    if (!_initialized) return;
    await cancelAll();
    if (!enabled.value) return;

    final debts = await DbHelper.instance.getAllDebts();
    for (final debt in debts) {
      if (!debt.isSettled && debt.dueDate != null && debt.id != null) {
        await syncDebtReminder(debt);
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> sendTestNotification() async {
    if (!_initialized) return;
    await requestPermission();
    try {
      await _plugin.show(
        999999,
        'Due Date Reminders Active',
        'You will receive offline reminders at 9:00 AM before your debts are due.',
        _notificationDetails(),
      );
    } catch (_) {}
  }

  Future<void> _scheduleOne({
    required int id,
    required DateTime scheduledLocalTime,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final delay = scheduledLocalTime.difference(now);
    if (delay <= const Duration(seconds: 5)) {
      return;
    }

    final scheduledTz = tz.TZDateTime.now(tz.local).add(delay);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    return const NotificationDetails(android: androidDetails);
  }

  int _dayBeforeId(int debtId) => debtId * 2;
  int _onDueDateId(int debtId) => debtId * 2 + 1;

  static ReminderTiming _timingFromString(String? raw) {
    switch (raw) {
      case 'day_before':
        return ReminderTiming.dayBefore;
      case 'on_due_date':
        return ReminderTiming.onDueDate;
      default:
        return ReminderTiming.both;
    }
  }

  static String _timingToString(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.dayBefore:
        return 'day_before';
      case ReminderTiming.onDueDate:
        return 'on_due_date';
      case ReminderTiming.both:
        return 'both';
    }
  }
}
