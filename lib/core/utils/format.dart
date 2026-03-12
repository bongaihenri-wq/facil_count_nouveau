import 'package:intl/intl.dart';

String formatCFA(num amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  final formatted = formatter.format(amount.abs());
  final sign = amount >= 0 ? '' : '-';
  return '$sign$formatted F CFA';
}