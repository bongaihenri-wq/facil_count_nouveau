import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/purchase_model.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

class PurchaseDashboard extends StatelessWidget {
  final List<PurchaseModel> purchases;

  const PurchaseDashboard({super.key, required this.purchases});

  Map<String, double> _getMonthlyTotals() {
    final totals = <String, double>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    for (final purchase in purchases) {
      final key = fmt.format(purchase.purchaseDate);
      totals[key] = (totals[key] ?? 0) + purchase.amount;
    }

    final sortedKeys = totals.keys.toList()
      ..sort((a, b) => fmt.parse(b).compareTo(fmt.parse(a)));

    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, totals[k]!)));
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();
    final now = DateTime.now();

    final currentMonthTotal = purchases
        .where(
          (p) =>
              p.purchaseDate.year == now.year &&
              p.purchaseDate.month == now.month,
        )
        .fold<double>(0, (sum, p) => sum + p.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Achats du mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (Formatters.formatCurrency(currentMonthTotal)),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
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
                  (Formatters.formatCurrency(entry.value)),
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
