import 'package:facil_count_nouveau/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/expense_model.dart';

class ExpenseDashboard extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const ExpenseDashboard({super.key, required this.expenses});

  Map<String, double> _getMonthlyTotals() {
    final totals = <String, double>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    for (final expense in expenses) {
      final key = fmt.format(expense.expensesDate);
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }

    final sortedKeys = totals.keys.toList()
      ..sort((a, b) => fmt.parse(b).compareTo(fmt.parse(a)));

    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, totals[k]!)));
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();
    final now = DateTime.now();

    final currentMonthTotal = expenses
        .where(
          (e) =>
              e.expensesDate.year == now.year &&
              e.expensesDate.month == now.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Dépenses du mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Formatters.formatCurrency(currentMonthTotal),
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
          const SizedBox(height: 24),
          ...monthlyTotals.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.key.toUpperCase()),
                trailing: Text(
                  Formatters.formatCurrency(entry.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
