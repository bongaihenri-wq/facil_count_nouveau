import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTime selectedDate;
  final Function(String) onPeriodChanged;
  final Function(DateTime) onDateChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Sélecteur de période
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Jour', label: Text('Jour')),
                  ButtonSegment(value: 'Semaine', label: Text('Sem.')),
                  ButtonSegment(value: 'Mois', label: Text('Mois')),
                  ButtonSegment(value: 'Année', label: Text('Année')),
                ],
                selected: {selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  onPeriodChanged(newSelection.first);
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sélecteur de date
            IconButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onDateChanged(picked);
              },
              icon: const Icon(Icons.calendar_today, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    if (selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      return "Aujourd'hui";
    }
    return DateFormat('dd/MM/yyyy').format(selectedDate);
  }
}
