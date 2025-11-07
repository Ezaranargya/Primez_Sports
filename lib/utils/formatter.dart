import 'package:intl/intl.dart';

class Formatter {
  static String formatPrice(double value) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    return formatter.format(value);
  }
}

