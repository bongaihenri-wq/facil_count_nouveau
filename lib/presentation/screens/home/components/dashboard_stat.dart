import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

class DashboardStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final double? evolution;
  final bool isInverse;

  const DashboardStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.evolution,
    this.isInverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEvolution = evolution != null;
    final bool isPositive = isInverse 
        ? (evolution ?? 0) <= 0
        : (evolution ?? 0) >= 0;
    
    final Color evolutionColor = isPositive ? Colors.green.shade300 : Colors.red.shade300;
    final IconData evolutionIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                if (hasEvolution) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: evolutionColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(evolutionIcon, color: evolutionColor, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${evolution!.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: evolutionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}