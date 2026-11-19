import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _myrFormat = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _shortMonthFormat = DateFormat('MMM');

  static String myr(double amount) => _myrFormat.format(amount);

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  static String shortMonth(DateTime date) => _shortMonthFormat.format(date);
}
