import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchasesDashboardView extends StatelessWidget {
  final double totalMoisActuel;
  final double difference;
  final Map<String, Map<String, num>> monthlyTotals;

  const PurchasesDashboardView({
    super.key,
    required this.totalMoisActuel,
    required this.difference,
    required this.monthlyTotals,
  });

  String formatCFA(num amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.abs())} F CFA';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFE3F2FD),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Achats du mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCFA(totalMoisActuel),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
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
                        color: difference >= 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatCFA(difference.abs())} vs mois préc.',
                        style: TextStyle(
                          fontSize: 15,
                          color: difference >= 0 ? Colors.green : Colors.red,
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
            final month = entry.key;
            final amount = entry.value['amount'] as num;
            final diff = entry.value['diff'] as num;
            final isIncrease = diff >= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCFA(amount.toDouble()),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              isIncrease
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isIncrease ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatCFA(diff.abs().toDouble()),
                              style: TextStyle(
                                color: isIncrease ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
