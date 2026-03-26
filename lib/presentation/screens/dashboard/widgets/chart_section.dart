import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class ChartSection extends ConsumerWidget {
  const ChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return state.when(
      data: (stats) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16), // ← Réduit de 20 à 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Évolution 12 mois',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ), // ← Réduit
                  ),
                  _buildLegend(),
                ],
              ),
              const SizedBox(height: 16), // ← Réduit de 20 à 16
              SizedBox(
                height: 200, // ← Réduit de 220 à 200
                child: BarChart(_getChartData(stats.monthlyEvolution)),
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox(
        height: 280, // ← Réduit
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min, // ← Ajouté pour éviter débordement
      children: [
        _LegendItem(color: Colors.blue.shade700, label: 'Ach.'),
        const SizedBox(width: 8),
        _LegendItem(color: Colors.green.shade700, label: 'Ven.'),
        const SizedBox(width: 8),
        _LegendItem(color: Colors.orange.shade700, label: 'Dép.'),
      ],
    );
  }

  BarChartData _getChartData(List<MonthlyData> data) {
    final maxY =
        data
            .expand((m) => [m.achats, m.ventes, m.depenses])
            .reduce((a, b) => a > b ? a : b) *
        1.1; // ← Réduit marge de 1.2 à 1.1

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY > 0 ? maxY : 1000,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = data[groupIndex].month;
            final monthName = DateFormat('MMM', 'fr_FR').format(month);
            String type = '';
            double value = 0;

            switch (rodIndex) {
              case 0:
                type = 'Achats';
                value = data[groupIndex].achats;
                break;
              case 1:
                type = 'Ventes';
                value = data[groupIndex].ventes;
                break;
              case 2:
                type = 'Dépenses';
                value = data[groupIndex].depenses;
                break;
            }

            return BarTooltipItem(
              '$monthName\n$type: ${Formatters.formatCurrency(value)}',
              const TextStyle(color: Colors.white, fontSize: 11), // ← Réduit
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // ← Ajouté
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                // Abréviations personnalisées pour gagner de la place
                final month = data[index].month;
                final abbrev = _getMonthAbbrev(month);

                return Padding(
                  padding: const EdgeInsets.only(top: 6), // ← Réduit
                  child: Text(
                    abbrev, // ← J, F, M, A, M, J, J, A, S, O, N, D
                    style: TextStyle(
                      fontSize: 10, // ← Réduit de 11 à 10
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // ← Réduit de 55 à 40
            getTitlesWidget: (value, meta) {
              String label;
              if (value >= 1000000) {
                label =
                    '${(value / 1000000).toStringAsFixed(0)}M'; // ← Sans décimale
              } else if (value >= 1000) {
                label = '${(value / 1000).toStringAsFixed(0)}K';
              } else {
                label = value.toStringAsFixed(0);
              }
              return Padding(
                padding: const EdgeInsets.only(
                  right: 4,
                ), // ← Marge pour éviter débordement
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9, // ← Réduit à 9
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 250, // ← Moins de lignes
      ),
      barGroups: List.generate(data.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            _buildRod(data[i].achats, Colors.blue.shade700),
            _buildRod(data[i].ventes, Colors.green.shade700),
            _buildRod(data[i].depenses, Colors.orange.shade700),
          ],
        );
      }),
    );
  }

  /// Abréviations ultra-courtes pour les mois
  String _getMonthAbbrev(DateTime date) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return months[date.month - 1];
  }

  BarChartRodData _buildRod(double value, Color color) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: 6, // ← Réduit de 8 à 6
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, // ← Réduit
          height: 10, // ← Réduit
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10, // ← Réduit
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
