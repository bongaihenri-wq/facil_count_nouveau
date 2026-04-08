import 'package:facil_count_nouveau/core/utils/date_filter_helper.dart';

import 'date_filter.dart'; // L'import pour la conversion vers votre type global

class DashboardDateRange {
  final DateTime? start;
  final DateTime? end;

  const DashboardDateRange({
    this.start,
    this.end,
  });

  /// Factory pour créer une plage couvrant le mois sélectionné ET le précédent
  factory DashboardDateRange.forComparison(DateTime selectedMonth) {
    // Premier jour du mois précédent (Dart gère le passage à l'année N-1 si month est 1)
    final startOfPrevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    
    // Dernier jour (23:59:59) du mois sélectionné
    // On prend le jour 1 du mois suivant (month + 1) et on retire une seconde
    final endOfCurrentMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    
    return DashboardDateRange(
      start: startOfPrevMonth,
      end: endOfCurrentMonth,
    );
  }

  /// Convertit ce modèle vers le type attendu par vos providers (le "Helper")
  DateFilterRange toDateFilterRange() {
    return DateFilterRange(
      start: start,
      end: end, label: '',
    );
  }

  // Égalité pour Riverpod (crucial pour les performances)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardDateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}