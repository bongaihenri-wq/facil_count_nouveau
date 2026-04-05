import 'package:flutter/material.dart';
import 'date_filter_helper.dart';

class PeriodPickerBottomSheet extends StatelessWidget {
  final Function(DateFilterRange) onPeriodSelected;

  const PeriodPickerBottomSheet({super.key, required this.onPeriodSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SÉLECTIONNER LA PÉRIODE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildOption(context, '☀️ Par Jour', PeriodType.jour),
              _buildOption(context, '🗓️ Semaine', PeriodType.semaine),
            ],
          ),
          Row(
            children: [
              _buildOption(context, '📅 Par Mois', PeriodType.mois),
              _buildOption(context, '📆 Par Année', PeriodType.annee),
            ],
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('🌍 Afficher tous les éléments', textAlign: TextAlign.center),
            onTap: () {
              onPeriodSelected(DateFilterHelper.calculateRange(PeriodType.tout, DateTime.now()));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, PeriodType type) {
    return Expanded(
      child: Card(
        child: ListTile(
          title: Text(title, textAlign: TextAlign.center),
          onTap: () async {
            if (type == PeriodType.tout) return;
            
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (picked != null) {
              final range = DateFilterHelper.calculateRange(type, picked);
              onPeriodSelected(range);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
