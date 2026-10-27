import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String currency(num amount) {
    return '${_currencyFormat.format(amount)} đ';
  }

  static String date(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String dateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  static String time(DateTime dt) {
    return _timeFormat.format(dt);
  }

  static String dateString(String yyyyMmDd) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return yyyyMmDd;
  }
}
