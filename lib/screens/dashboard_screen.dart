import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
// Correction : Suppression du caractère spécial et vérification du package
import 'package:facil_count_nouveau/screens/cash_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  String _selectedPeriod = 'Mois';

  double _totalAchats = 0;
  double _totalVentes = 0;
  double _totalDepenses = 0;
  double _marge = 0;

  List<Map<String, double>> _monthlyEvolution = [];

  List<Map<String, dynamic>> _bestSoldProducts = [];
  List<Map<String, dynamic>> _leastSoldProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      DateTime? periodStart;
      DateTime periodEnd = now;

      if (_selectedPeriod == 'Semaine') {
        periodStart = now.subtract(Duration(days: now.weekday - 1));
      } else if (_selectedPeriod == 'Mois') {
        periodStart = DateTime(now.year, now.month, 1);
      } else if (_selectedPeriod == 'Année') {
        periodStart = DateTime(now.year, 1, 1);
      }

      _totalAchats = await _getTotal('purchases', 'purchase_date', periodStart, periodEnd);
      _totalVentes = await _getTotal('sales', 'sale_date', periodStart, periodEnd);
      _totalDepenses = await _getTotal('expenses', 'created_at', periodStart, periodEnd);
      _marge = _totalVentes - _totalAchats - _totalDepenses;

      _monthlyEvolution = await _getMonthlyEvolution();
      await _getProductStats(periodStart, periodEnd);

      if (mounted) setState(() => _isLoading = false);
    } catch (e, stack) {
      print('Erreur dashboard: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement : $e')),
        );
      }
    }
  }

  Future<double> _getTotal(
    String table,
    String dateColumn,
    DateTime? start,
    DateTime? end,
  ) async {
    var query = supabase.from(table).select('amount');
    if (start != null) query = query.gte(dateColumn, start.toIso8601String());
    if (end != null) query = query.lte(dateColumn, end.toIso8601String());

    final res = await query;
    // Correction du fold pour éviter l'erreur FutureOr
    return (res as List).fold<double>(0.0, (sum, row) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      return sum + amount;
    });
  }

  Future<List<Map<String, double>>> _getMonthlyEvolution() async {
    final now = DateTime.now();
    final List<Map<String, double>> evolution = [];

    for (int i = 0; i < 12; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

      final achats = await _getTotal('purchases', 'purchase_date', monthStart, monthEnd);
      final ventes = await _getTotal('sales', 'sale_date', monthStart, monthEnd);
      final depenses = await _getTotal('expenses', 'created_at', monthStart, monthEnd);

      evolution.add({'achats': achats, 'ventes': ventes, 'depenses': depenses});
    }
    return evolution.reversed.toList();
  }

  Future<void> _getProductStats(DateTime? start, DateTime? end) async {
    var query = supabase.from('sales').select('product_id, quantity, products!inner(name)');

    if (start != null) query = query.gte('sale_date', start.toIso8601String());
    if (end != null) query = query.lte('sale_date', end.toIso8601String());

    final res = await query;

    final Map<String, double> productSales = {};
    for (final sale in res) {
      final name = (sale['products'] as Map?)?['name'] as String? ?? 'Inconnu';
      final qty = (sale['quantity'] as num?)?.toDouble() ?? 0.0;
      productSales[name] = (productSales[name] ?? 0.0) + qty;
    }

    final sorted = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    _bestSoldProducts = sorted.take(5).map((e) => {'name': e.key, 'quantity': e.value}).toList();
    _leastSoldProducts = sorted.reversed.take(5).map((e) => {'name': e.key, 'quantity': e.value}).toList();
  }

  String formatCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final sign = amount >= 0 ? '' : '-';
    return '$sign${formatter.format(amount.abs())} F CFA';
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'Semaine':
        return 'de la semaine';
      case 'Mois':
        return 'du mois';
      case 'Année':
        return 'de l\'année';
      default:
        return 'globale';
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = _getPeriodLabel(_selectedPeriod);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['Semaine', 'Mois', 'Année', 'Toutes'].map((period) {
                          final isSelected = period == _selectedPeriod;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: FilterChip(
                              label: Text(period),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() {
                                    _selectedPeriod = period;
                                    _fetchData();
                                  });
                                }
                              },
                              selectedColor: Colors.blue.shade700,
                              backgroundColor: Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCompactCard('Achats', _totalAchats, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCompactCard('Ventes', _totalVentes, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCompactCard('Dépenses', _totalDepenses, Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      color: _marge >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Marge nette $periodLabel',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCFA(_marge),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _marge >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Évolution mensuelle',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: _monthlyEvolution.isEmpty 
                                ? const Center(child: Text("Pas de données"))
                                : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _monthlyEvolution
                                              .expand((m) => [m['achats'] ?? 0, m['ventes'] ?? 0, m['depenses'] ?? 0])
                                              .reduce((a, b) => a > b ? a : b) * 1.3,
                                    barTouchData: BarTouchData(enabled: true),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 && index < _monthlyEvolution.length) {
                                              return Text(DateFormat('MMM', 'fr_FR').format(DateTime.now().subtract(Duration(days: 30 * (11 - index)))), style: const TextStyle(fontSize: 9));
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    barGroups: List.generate(_monthlyEvolution.length, (i) {
                                      final data = _monthlyEvolution[i];
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(toY: data['achats'] ?? 0, color: Colors.blue, width: 6),
                                          BarChartRodData(toY: data['ventes'] ?? 0, color: Colors.green, width: 6),
                                          BarChartRodData(toY: data['depenses'] ?? 0, color: Colors.red, width: 6),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProductList('Top 5 produits vendus', _bestSoldProducts, Colors.green),
                    const SizedBox(height: 16),
                    _buildProductList('5 produits les moins vendus', _leastSoldProducts, Colors.red),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavButton('Caisse', Icons.point_of_sale, Colors.indigo, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CashScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductList(String title, List<Map<String, dynamic>> products, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...products.map((p) => ListTile(
              leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Text("${(p['quantity'] as double).toInt()}", style: TextStyle(color: color))),
              title: Text(p['name'] as String),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(140, 50)),
      onPressed: onPressed,
    );
  }

  Widget _buildCompactCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            FittedBox(child: Text(formatCFA(value), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
          ],
        ),
      ),
    );
  }
}