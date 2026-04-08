import 'package:flutter/material.dart';

class DashboardDateRange {
  final DateTime? start;
  final DateTime? end;

  const DashboardDateRange({
    this.start,
    this.end,
  });

  /// Filtre pour un mois unique
  factory DashboardDateRange.month(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return DashboardDateRange(start: start, end: end);
  }

  /// Filtre pour le dashboard (Mois actuel + précédent)
  factory DashboardDateRange.forComparison(DateTime selectedMonth) {
    final start = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);
    return DashboardDateRange(start: start, end: end);
  }

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
