import 'package:flutter/material.dart';

class SaleDashboard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const SaleDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final currentMonth = (stats['current_month'] as num?)?.toDouble() ?? 0;
    final previousMonth = (stats['previous_month'] as num?)?.toDouble() ?? 0;
    final difference = (stats['difference'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [_buildMainCard(currentMonth, difference)]),
    );
  }

  Widget _buildMainCard(double current, double diff) {
    final isIncrease = diff >= 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Ventes du mois',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '${current.toStringAsFixed(0)} CFA',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncrease ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  '${diff.abs().toStringAsFixed(0)} CFA vs mois préc.',
                  style: TextStyle(
                    color: isIncrease ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
