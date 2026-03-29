// lib/presentation/screens/purchases/purchase_dashboard.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/purchase_model.dart';
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
        .where((p) => p.purchaseDate.year == now.year && p.purchaseDate.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final previousMonthTotal = purchases
        .where((p) =>
            p.purchaseDate.year == previousMonth.year &&
            p.purchaseDate.month == previousMonth.month)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final difference = currentMonthTotal - previousMonthTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.blue.shade50, // 🔥 BLEU
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
                    Formatters.formatCurrency(currentMonthTotal),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800, // 🔥 BLEU
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        difference >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: difference >= 0 ? Colors.blue : Colors.red, // 🔥 BLEU si positif
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${Formatters.formatCurrency(difference.abs())} vs mois préc.',
                        style: TextStyle(
                          color: difference >= 0 ? Colors.blue : Colors.red, // 🔥 BLEU si positif
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
