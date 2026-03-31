import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../dashboard/dashboard_screen.dart';

// Provider pour le mois sélectionné
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Provider des stats adapté au mois sélectionné
final selectedMonthStatsProvider = Provider<MonthStats>((ref) {
  final sales = ref.watch(filteredSalesProvider);
  final purchases = ref.watch(filteredPurchasesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  
  final currentMonth = DateTime(selectedMonth.year, selectedMonth.month);
  final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);

  final currentMonthSales = sales
      .where((s) => s.saleDate.year == currentMonth.year && s.saleDate.month == currentMonth.month)
      .fold(0.0, (sum, s) => sum + s.amount);

  final currentMonthPurchases = purchases
      .where((p) => p.purchaseDate.year == currentMonth.year && p.purchaseDate.month == currentMonth.month)
      .fold(0.0, (sum, p) => sum + p.amount);

  final prevMonthSales = sales
      .where((s) => s.saleDate.year == prevMonth.year && s.saleDate.month == prevMonth.month)
      .fold(0.0, (sum, s) => sum + s.amount);

  final prevMonthPurchases = purchases
      .where((p) => p.purchaseDate.year == prevMonth.year && p.purchaseDate.month == prevMonth.month)
      .fold(0.0, (sum, p) => sum + p.amount);

  return MonthStats(
    sales: currentMonthSales,
    purchases: currentMonthPurchases,
    margin: currentMonthSales - currentMonthPurchases,
    prevMonthSales: prevMonthSales,
    prevMonthPurchases: prevMonthPurchases,
    prevMonthMargin: prevMonthSales - prevMonthPurchases,
    selectedMonth: selectedMonth,
  );
});

class MonthStats {
  final double sales;
  final double purchases;
  final double margin;
  final double prevMonthSales;
  final double prevMonthPurchases;
  final double prevMonthMargin;
  final DateTime selectedMonth;

  MonthStats({
    required this.sales,
    required this.purchases,
    required this.margin,
    required this.prevMonthSales,
    required this.prevMonthPurchases,
    required this.prevMonthMargin,
    required this.selectedMonth,
  });

  double get salesEvolution => _calculateEvolution(prevMonthSales, sales);
  double get purchasesEvolution => _calculateEvolution(prevMonthPurchases, purchases);
  double get marginEvolution => _calculateEvolution(prevMonthMargin, margin);

  double _calculateEvolution(double previous, double current) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  bool get isSalesPositive => salesEvolution >= 0;
  bool get isPurchasesPositive => purchasesEvolution <= 0;
  bool get isMarginPositive => marginEvolution >= 0;
  
  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }
}

class DashboardCard extends ConsumerWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(selectedMonthStatsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Réduit de 20 à 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!stats.isCurrentMonth)
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ARCHIVE',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => _showMonthPicker(context, ref, selectedMonth),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getMonthYearName(selectedMonth),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white.withOpacity(0.9),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Tableau de bord',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getGlobalTrendColor(stats).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getGlobalTrendIcon(stats),
                      color: _getGlobalTrendColor(stats),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ✅ CARDS PLUS HAUTES (140px au lieu de 120px)
              SizedBox(
                height: 140,
                child: PageView(
                  controller: PageController(viewportFraction: 0.88), // Légèrement plus large
                  padEnds: false,
                  children: [
                    _buildStatCard(
                      label: 'Ventes',
                      value: stats.sales,
                      evolution: stats.salesEvolution,
                      icon: Icons.arrow_upward,
                      color: Colors.green.shade300,
                      isPositive: stats.isSalesPositive,
                    ),
                    _buildStatCard(
                      label: 'Achats',
                      value: stats.purchases,
                      evolution: stats.purchasesEvolution,
                      icon: Icons.arrow_downward,
                      color: Colors.orange.shade300,
                      isPositive: stats.isPurchasesPositive,
                      isInverse: true,
                    ),
                    _buildStatCard(
                      label: 'Marge',
                      value: stats.margin,
                      evolution: stats.marginEvolution,
                      icon: Icons.show_chart,
                      color: Colors.white,
                      isPositive: stats.isMarginPositive,
                    ),
                  ],
                ),
              ),
              
              // Indicateur de page
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDotIndicator(Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  _buildDotIndicator(Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 6),
                  _buildDotIndicator(Colors.white.withOpacity(0.4)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Bouton détail compact
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Voir le détail',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(initialDate: current),
    );
    
    if (selected != null) {
      ref.read(selectedMonthProvider.notifier).state = selected;
    }
  }

  String _getMonthYearName(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ✅ CARD PLUS HAUTE AVEC VARIATION EN BLANC
  Widget _buildStatCard({
    required String label,
    required double value,
    required double evolution,
    required IconData icon,
    required Color color,
    required bool isPositive,
    bool isInverse = false,
  }) {
    final Color evolutionColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final IconData evolutionIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              // ✅ FOND BLANC POUR LA VARIATION
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white, // FOND BLANC
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(evolutionIcon, color: evolutionColor, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '${evolution.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: evolutionColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.formatCurrency(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22, // Légèrement réduit pour éviter débordement
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  IconData _getGlobalTrendIcon(MonthStats stats) {
    if (stats.isMarginPositive && stats.isSalesPositive) return Icons.trending_up;
    if (!stats.isMarginPositive && !stats.isSalesPositive) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getGlobalTrendColor(MonthStats stats) {
    if (stats.isMarginPositive && stats.isSalesPositive) return Colors.green.shade300;
    if (!stats.isMarginPositive && !stats.isSalesPositive) return Colors.red.shade300;
    return Colors.orange.shade300;
  }
}

// Dialog de sélection mois/année (compact)
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthYearPickerDialog({required this.initialDate});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  final months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionner une période',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélection Année compacte
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    if (selectedYear > years.last) {
                      setState(() => selectedYear--);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    if (selectedYear < years.first) {
                      setState(() => selectedYear++);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grille des mois compacte
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: months.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final month = entry.value;
                final isSelected = index == selectedMonth;
                final isCurrent = index == DateTime.now().month && 
                                  selectedYear == DateTime.now().year;
                
                return InkWell(
                  onTap: () => setState(() => selectedMonth = index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 65,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.blue 
                          : isCurrent 
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: isCurrent && !isSelected
                          ? Border.all(color: Colors.blue, width: 1)
                          : null,
                    ),
                    child: Text(
                      month.substring(0, 3),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected || isCurrent 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Boutons compacts
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Annuler', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context, 
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Valider', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
