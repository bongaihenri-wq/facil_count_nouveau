import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/expense_model.dart';
import '/presentation/providers/expense_provider.dart';
import '../dialogs/edit_expense_dialog.dart';
import 'expense_card.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

final selectedPeriodProvider = StateProvider<String>((ref) => 'Mois');

class ExpenseList extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const ExpenseList({super.key, required this.expenses});

  List<ExpenseModel> _filterByPeriod(
    List<ExpenseModel> expenses,
    String period,
  ) {
    final now = DateTime.now();
    return expenses.where((e) {
      switch (period) {
        case 'Semaine':
          return e.expensesDate.isAfter(now.subtract(const Duration(days: 7)));
        case 'Mois':
          return e.expensesDate.month == now.month &&
              e.expensesDate.year == now.year;
        case 'Année':
          return e.expensesDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final filtered = _filterByPeriod(expenses, selectedPeriod);

    if (filtered.isEmpty) {
      return const Center(child: Text('Aucune dépense trouvée'));
    }

    final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        _buildTotalCard(total),
        _buildPeriodFilterChips(ref, selectedPeriod),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => ExpenseCard(
              expense: filtered[index],
              onEdit: () => _showEditDialog(context, ref, filtered[index]),
              onDelete: () => _confirmDelete(context, ref, filtered[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Total dépenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                Formatters.formatCurrency(total),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips(WidgetRef ref, String selectedPeriod) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semaine', 'Mois', 'Année'].map((period) {
            final isSelected = period == selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(selectedPeriodProvider.notifier).state = period,
                selectedColor: Colors.red.shade700,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) {
    if (expense.locked) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text('Dépense verrouillée'),
            ],
          ),
          content: const Text(
            'Cette dépense est verrouillée et ne peut pas être modifiée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } else {
      showEditExpenseDialog(context, expense);
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('${expense.name} - ${expense.formattedAmount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(expenseNotifierProvider.notifier)
                  .deleteExpense(expense.id);
              ref.invalidate(filteredExpensesProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
