import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/repositories/lock_repository.dart';
import '/presentation/providers/auth_provider.dart';
import '/presentation/providers/expense_provider.dart';
import '../dialogs/edit_expense_dialog.dart';
import 'expense_card.dart';

class ExpenseList extends ConsumerWidget {
  final List<ExpenseModel> expenses;

  const ExpenseList({super.key, required this.expenses});

  bool _isAdmin(WidgetRef ref) {
    final role = ref.read(authProvider).currentUser?.role;
    return role == 'admin' || role == 'super_admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'Aucune dépense trouvée pour cette période',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: expense.locked
                      ? Border.all(color: Colors.orange.shade300, width: 1.5)
                      : null,
                ),
                child: ExpenseCard(
                  expense: expense,
                  onEdit: () => _showEditDialog(context, ref, expense),
                  onDelete: () => _confirmDelete(context, ref, expense),
                ),
              ),
              if (expense.locked)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _showLockedInfo(context, ref, expense),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Icon(Icons.lock, size: 14, color: Colors.orange.shade800),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    if (expense.locked) {
      _showLockedInfo(context, ref, expense);
      return;
    }
    showEditExpenseDialog(context, expense);
  }

  void _showLockedInfo(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    final isAdmin = _isAdmin(ref);
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
        content: Text(
          '${expense.name} — ${expense.formattedAmount}\n\n'
          'Cette dépense est protégée (point de contrôle).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          if (isAdmin)
            TextButton.icon(
              icon: const Icon(Icons.lock_open, color: Colors.red, size: 18),
              label: const Text('Déverrouiller', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await LockRepository().toggleSingle(
                    actionType: 'Dépenses', id: expense.id, lock: false);
                  ref.invalidate(filteredExpensesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔓 Dépense déverrouillée')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red));
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    if (expense.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Impossible de supprimer une dépense verrouillée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('${expense.name} - ${expense.formattedAmount}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
              ref.invalidate(filteredExpensesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}