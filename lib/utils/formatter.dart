  import 'package:intl/intl.dart';

  class Formatter{
    static String currency(double value) {
      final format = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0, 
      );
      return format.format(value);
    }
  }