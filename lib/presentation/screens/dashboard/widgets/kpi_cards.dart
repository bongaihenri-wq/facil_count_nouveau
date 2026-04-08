import 'package:flutter/material.dart';
import '../../dashboard/providers/dashboard_provider.dart'; // Pour DashboardGlobalData
import '/../core/utils/formatters.dart';

class KPICards extends StatelessWidget {
  final DashboardGlobalData stats; // 👈 AJOUTÉ ICI

  const KPICards({super.key, required this.stats}); // 👈 AJOUTÉ ICI

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard('Ventes', '${Formatters.formatCurrency(stats.totalVentes)} FCFA', Colors.green),
        const SizedBox(width: 12),
        _buildStatCard('Achats', '${Formatters.formatCurrency(stats.totalAchats)} FCFA', Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Dépenses', '${Formatters.formatCurrency(stats.totalDepenses)} FCFA', Colors.grey),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}