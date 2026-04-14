import 'package:flutter/material.dart';
import '/../core/utils/formatters.dart';

class ChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyEvolution;

  const ChartSection({super.key, required this.monthlyEvolution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Mensuelle',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          if (monthlyEvolution.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: Text('Aucune donnée sur cette période', style: TextStyle(color: Colors.grey))),
            )
          else
            SizedBox(
              height: 170,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyEvolution.map((data) {
                  return _buildBar(context, data);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, Map<String, dynamic> data) {
    final double ventes = data['ventes'] ?? 0.0;
    // On prend la plus grosse valeur pour donner une échelle de hauteur
    final double maxVal = monthlyEvolution.map((e) => e['ventes'] as double).reduce((a, b) => a > b ? a : b);
    final double percentage = maxVal > 0 ? (ventes / maxVal) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          ventes > 0 ? '${(ventes / 1000).toStringAsFixed(0)}k' : '0',
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 100 * percentage.clamp(0.1, 1.0), // Évite les hauteurs à 0
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data['month'],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}
