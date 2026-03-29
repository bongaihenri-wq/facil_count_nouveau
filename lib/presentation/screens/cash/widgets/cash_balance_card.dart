// lib/presentation/screens/cash/widgets/cash_balance_card.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

class CashBalanceCard extends StatelessWidget {
  final double netFlow;
  final double totalIn;
  final double totalOut;
  final DateTime selectedDate;
  final VoidCallback onDateTap;

  const CashBalanceCard({
    super.key,
    required this.netFlow,
    required this.totalIn,
    required this.totalOut,
    required this.selectedDate,
    required this.onDateTap,
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
                ? [Colors.green.shade50, Colors.white]
                : [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Date du solde - CLIQUABLE
              InkWell(
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Solde au ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Colors.blue.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Montant du solde CUMULÉ
              Text(
                Formatters.formatCurrency(netFlow),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solde cumulé',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Entrées et Sorties cumulées
              Row(
                children: [
                  Expanded(
                    child: _buildFlowItem(
                      label: 'Total Entrées',
                      amount: totalIn,
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildFlowItem(
                      label: 'Total Sorties',
                      amount: totalOut,
                      color: Colors.red,
                      icon: Icons.arrow_upward,
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
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.shade600),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCompactCurrency(amount),
          style: TextStyle(
            color: color.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
