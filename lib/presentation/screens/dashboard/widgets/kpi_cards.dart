import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class KPICards extends ConsumerWidget {
  const KPICards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return state.when(
      data: (stats) => Column(
        children: [
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _KPICard(
                  title: 'Achats',
                  value: stats.totalAchats,
                  icon: Icons.shopping_cart,
                  color: Colors.blue.shade700,
                ),
                _KPICard(
                  title: 'Ventes',
                  value: stats.totalVentes,
                  icon: Icons.point_of_sale,
                  color: Colors.green.shade700,
                ),
                _KPICard(
                  title: 'Dépenses',
                  value: stats.totalDepenses,
                  icon: Icons.receipt_long,
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _MargeCard(stats),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 3,
        shadowColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LIGNE 1 : Icône + Titre
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // LIGNE 2 : Montant + F CFA centrés
              Center(
                // ← CENTRE LE CONTENU
                child: Column(
                  children: [
                    Text(
                      _formatWithoutCurrency(value),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // F CFA centré sous le montant
                    Text(
                      'F CFA',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWithoutCurrency(double value) {
    return Formatters.formatNumber(value.toInt());
  }
}

class _MargeCard extends StatelessWidget {
  final DashboardStats stats;

  const _MargeCard(this.stats);

  @override
  Widget build(BuildContext context) {
    final isProfitable = stats.isProfitable;

    return Card(
      elevation: 4,
      color: isProfitable ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isProfitable ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfitable ? Icons.trending_up : Icons.trending_down,
                  color: isProfitable
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Marge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isProfitable
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Montant + F CFA centrés
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatWithoutCurrency(stats.marge),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isProfitable
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'F CFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: isProfitable
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isProfitable
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${stats.margePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: isProfitable
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWithoutCurrency(double value) {
    return Formatters.formatNumber(value.toInt());
  }
}
