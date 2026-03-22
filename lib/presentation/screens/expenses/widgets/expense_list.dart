import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/expense_model.dart';
import '/presentation/providers/expense_provider.dart';
import 'expense_card.dart';

class ExpenseList extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const Center(child: Text('Aucune dépense trouvée'));
    }

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        _buildTotalCard(total),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: expenses.length,
            itemBuilder: (context, index) => ExpenseCard(
              expense: expenses[index],
              onEdit: () => _showEditDialog(context, ref, expenses[index]),
              onDelete: () => _confirmDelete(context, ref, expenses[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(double total) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total dépenses', style: TextStyle(fontSize: 16)),
              Text(
                '${total.toStringAsFixed(0)} CFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) {
    // TODO: Implémenter le dialogue d'édition
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier (à implémenter)'),
        content: Text(expense.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        content: Text(
          '${expense.name} - ${expense.amount.toStringAsFixed(0)} CFA',
        ),
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
