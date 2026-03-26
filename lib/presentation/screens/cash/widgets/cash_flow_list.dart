import 'package:flutter/material.dart';
import '/../../core/utils/formatters.dart';

class CashFlowItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isNegative;

  const CashFlowItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isNegative = false,
  });
}

class CashFlowList extends StatelessWidget {
  final List<CashFlowItem> inItems;
  final List<CashFlowItem> outItems;

  const CashFlowList({
    super.key,
    required this.inItems,
    required this.outItems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entrées
            _buildSectionTitle('Entrées', Colors.green),
            const SizedBox(height: 12),
            ...inItems.map((item) => _buildFlowRow(item)),
            const Divider(height: 32),
            // Sorties
            _buildSectionTitle('Sorties', Colors.red),
            const SizedBox(height: 12),
            ...outItems.map((item) => _buildFlowRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 109, 233, 189),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            title == 'Entrées' ? Icons.arrow_downward : Icons.arrow_upward,
            color: const Color.fromARGB(255, 206, 182, 0),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowRow(CashFlowItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCompactCurrency(item.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: item.isNegative ? Colors.red.shade700 : item.color,
                ),
              ),
              Text(
                'F CFA',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
