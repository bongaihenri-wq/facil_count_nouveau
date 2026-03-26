import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

class CashBalanceCard extends StatelessWidget {
  final double netFlow;
  final double totalIn;
  final double totalOut;

  const CashBalanceCard({
    super.key,
    required this.netFlow,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netFlow >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.red.shade50, Colors.red.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.account_balance_wallet : Icons.warning,
                    color: color.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Solde de Caisse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                Formatters.formatCurrency(netFlow),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFlowItem(
                      label: 'Entrées',
                      amount: totalIn,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildFlowItem(
                      label: 'Sorties',
                      amount: totalOut,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowItem({
    required String label,
    required double amount,
    required MaterialColor color,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCompactCurrency(amount),
          style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
