import 'package:intl/intl.dart';

enum PeriodType { jour, semaine, mois, annee, tout }

class DateFilterRange {
  final DateTime? start;
  final DateTime? end;
  final String label;

  DateFilterRange({this.start, this.end, required this.label});
}

class DateFilterHelper {
  /// Calcule la plage de date exacte en fonction du type et de la date choisie
  static DateFilterRange calculateRange(PeriodType type, DateTime selectedDate) {
    switch (type) {
      case PeriodType.jour:
        final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
        final end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        final label = DateFormat('EEEE dd MMM yyyy', 'fr_FR').format(selectedDate);
        return DateFilterRange(start: start, end: end, label: label);

      case PeriodType.semaine:
        // Trouver le lundi de cette semaine
        final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        
        final sunday = monday.add(const Duration(days: 6));
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        
        final label = "Sem. du ${DateFormat('dd MMM', 'fr_FR').format(start)} au ${DateFormat('dd MMM yyyy', 'fr_FR').format(end)}";
        return DateFilterRange(start: start, end: end, label: label);

      case PeriodType.mois:
        final start = DateTime(selectedDate.year, selectedDate.month, 1, 0, 0, 0);
        final end = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        final label = DateFormat('MMMM yyyy', 'fr_FR').format(selectedDate);
        return DateFilterRange(start: start, end: end, label: label);

      case PeriodType.annee:
        final start = DateTime(selectedDate.year, 1, 1, 0, 0, 0);
        final end = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
        final label = DateFormat('yyyy', 'fr_FR').format(selectedDate);
        return DateFilterRange(start: start, end: end, label: label);

      case PeriodType.tout:
        return DateFilterRange(start: null, end: null, label: "Tous les éléments");
        
    }
  }
  /// 🟢 Retourne la période par défaut (Mois en cours)
  static DateFilterRange defaultRange() {
    return calculateRange(PeriodType.mois, DateTime.now());
  }
}

