import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/expense_model.dart';
import '/presentation/providers/expense_provider.dart';
import '../dialogs/edit_expense_dialog.dart';
import 'expense_card.dart';

class ExpenseList extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si la liste est vide après l'application du filtre de date
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'Aucune dépense trouvée pour cette période',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // On retourne DIRECTEMENT la liste pure sans Header ni Chips
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ExpenseCard(
            expense: expense,
            onEdit: () => _showEditDialog(context, ref, expense),
            onDelete: () => _confirmDelete(context, ref, expense),
          ),
        );
      },
    );
  }

  // 🛡️ Garde-fous pour la modification
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

  // 🗑️ Boîte de dialogue de confirmation de suppression
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
