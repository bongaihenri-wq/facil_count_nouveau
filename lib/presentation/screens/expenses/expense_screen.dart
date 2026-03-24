import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';
import 'dialogs/add_expense_dialog.dart';
import 'dialogs/filter_dialog.dart';
import 'widgets/expense_dashboard.dart';
import 'widgets/expense_list.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(expenseTabProvider);
    final expensesAsync = ref.watch(filteredExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddExpenseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.red.shade50,
            child: Row(
              children: [
                _buildTab(context, ref, 'Liste', 0),
                _buildTab(context, ref, 'Dashboard', 1),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: expensesAsync.when(
              data: (expenses) => tabIndex == 0
                  ? ExpenseList(expenses: expenses)
                  : ExpenseDashboard(expenses: expenses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    int index,
  ) {
    final currentTab = ref.watch(expenseTabProvider);
    final isSelected = currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(expenseTabProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.red.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.red.shade700 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showExpenseFilterDialog(context);
  }
}
