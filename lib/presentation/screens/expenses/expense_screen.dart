import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/expense_list.dart';
import 'widgets/expense_dashboard.dart';
import 'dialogs/add_expense_dialog.dart';
import '/presentation/providers/expense_provider.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final statsAsync = ref.watch(expenseStatsProvider);
    final selectedTab = ref.watch(expenseTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => Column(
          children: [
            _buildTabBar(context, ref),
            Expanded(
              child: selectedTab == 0
                  ? ExpenseList(expenses: expenses)
                  : ExpenseDashboard(stats: statsAsync.valueOrNull ?? {}),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange.shade700,
        onPressed: () => showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(expenseTabProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TabButton(
            label: 'Liste',
            selected: selectedTab == 0,
            onTap: () => ref.read(expenseTabProvider.notifier).state = 0,
            color: Colors.orange.shade700,
          ),
          _TabButton(
            label: 'Dashboard',
            selected: selectedTab == 1,
            onTap: () => ref.read(expenseTabProvider.notifier).state = 1,
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  void _showFilter(BuildContext context, WidgetRef ref) {
    // TODO: Implémenter le filtre
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Filtres (à implémenter)'),
        ),
      ),
    );
  }
}

extension on AsyncValue<Map<String, dynamic>> {
  Map<String, dynamic>? get valueOrNull => null;
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
