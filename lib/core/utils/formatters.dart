import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat.decimalPattern('fr_FR');

  /// Format : 1 234 567 CFA
  static String formatCurrency(double amount) {
    return '${_currencyFormat.format(amount).trim()} CFA';
  }

  /// Format : 1 234 567
  static String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  /// Format : 1 234,56
  static String formatDecimal(double number) {
    return _numberFormat.format(number);
  }
}
