import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/expense_provider.dart';

void showExpenseFilterDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _FilterDialogContent(),
  );
}

class _FilterDialogContent extends ConsumerStatefulWidget {
  const _FilterDialogContent();

  @override
  ConsumerState<_FilterDialogContent> createState() =>
      _FilterDialogContentState();
}

class _FilterDialogContentState extends ConsumerState<_FilterDialogContent> {
  final _searchCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 MARGE EN BAS avec MediaQuery
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 25;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding, // 🔥 Marge du bas
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer les dépenses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Recherche texte
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Rechercher (nom, bénéficiaire...)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  label: Text(
                    _startDate == null
                        ? 'Du'
                        : DateFormat('dd/MM/yyyy').format(_startDate!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  label: Text(
                    _endDate == null
                        ? 'Au'
                        : DateFormat('dd/MM/yyyy').format(_endDate!),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref.read(expenseFiltersProvider.notifier).state =
                      const ExpenseFilters();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Réinitialiser'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(expenseFiltersProvider.notifier)
                      .state = ExpenseFilters(
                    searchQuery: _searchCtrl.text.trim().isEmpty
                        ? null
                        : _searchCtrl.text.trim(),
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Appliquer'),
              ),
            ],
          ),
          const SizedBox(height: 20), // 🔥 MARGE SUPPLÉMENTAIRE
        ],
      ),
    );
  }
}
