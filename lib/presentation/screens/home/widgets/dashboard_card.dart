import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';

// Imports des modèles avec gestion du conflit de nom
import '/../data/models/date_filter.dart' hide DashboardDateRange; 
import '/../../data/models/dashboard_date_range.dart';

// Import des providers
import '../../../providers/sale_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../dashboard/dashboard_screen.dart';

/// Stocke le mois sélectionné par l'utilisateur
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Calcule les statistiques pour le Dashboard
final selectedMonthStatsProvider = FutureProvider<MonthStats>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);

  // 1. On crée le filtre couvrant le mois actuel et le précédent
  final dashboardRange = DashboardDateRange.forComparison(selectedMonth);
  
  // Utilisation de la méthode de conversion pour satisfaire les providers family
  final filterForProviders = dashboardRange.toDateFilterRange();

  // 2. Récupération asynchrone des données
  final sales = await ref.watch(salesProvider(filterForProviders).future);
  final purchases = await ref.watch(purchasesProvider(filterForProviders).future);
  final expenses = await ref.watch(expensesProvider(filterForProviders).future);

  // Bornes temporelles pour le calcul local
  final currentStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final prevStart = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
  final nextMonthStart = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

  // Helper interne pour calculer le total sur une plage précise
  double sumRange(List<dynamic> items, DateTime start, DateTime end, DateTime? Function(dynamic) getDate) {
    return items.where((item) {
      final d = getDate(item);
      if (d == null) return false;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end);
    }).fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
  }

  return MonthStats(
    sales: sumRange(sales, currentStart, nextMonthStart, (i) => i.saleDate),
    purchases: sumRange(purchases, currentStart, nextMonthStart, (i) => i.purchaseDate),
    expenses: sumRange(expenses, currentStart, nextMonthStart, (i) => i.date ?? i.expensesDate),
    
    prevMonthSales: sumRange(sales, prevStart, currentStart, (i) => i.saleDate),
    prevMonthPurchases: sumRange(purchases, prevStart, currentStart, (i) => i.purchaseDate),
    prevMonthExpenses: sumRange(expenses, prevStart, currentStart, (i) => i.date ?? i.expensesDate),
    
    selectedMonth: selectedMonth,
  );
});

// --- WIDGET PRINCIPAL ---

class DashboardCard extends ConsumerWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(selectedMonthStatsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return statsAsync.when(
      loading: () => _buildBaseContainer(
        child: const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white))),
      ),
      error: (err, stack) => _buildBaseContainer(
        child: const SizedBox(height: 150, child: Center(child: Text("Erreur de données", style: TextStyle(color: Colors.white)))),
      ),
      data: (stats) => _buildBaseContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, selectedMonth, stats.isCurrentMonth),
            const SizedBox(height: 16),
            _buildStatsGrid(stats),
            const SizedBox(height: 16),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseContainer({required Widget child}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime date, bool isCurrent) {
    final months = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _selectMonth(context, ref, date),
              child: Row(
                children: [
                  Text("${months[date.month-1]} ${date.year}", 
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                ],
              ),
            ),
            Text(isCurrent ? "Performance Actuelle" : "Archive Mensuelle", 
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        if (!isCurrent)
          const Icon(Icons.history, color: Colors.white30, size: 28),
      ],
    );
  }

  Widget _buildStatsGrid(MonthStats stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatBox("VENTES", stats.sales, stats.salesEvolution, Colors.greenAccent),
          _buildStatBox("ACHATS", stats.purchases, stats.purchasesEvolution, Colors.orangeAccent),
          _buildStatBox("DÉPENSES", stats.expenses, stats.expensesEvolution, Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, double val, double evolution, Color color) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(Formatters.formatCurrency(val), 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(evolution >= 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: color),
              Text(" ${evolution.abs().toStringAsFixed(1)}%", 
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
        child: const Text("VOIR ANALYSES DÉTAILLÉES", 
          style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Renommé de _selectDate à _selectMonth pour correspondre à l'appel dans le Header
  void _selectMonth(BuildContext context, WidgetRef ref, DateTime current) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(initialDate: current),
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state = picked;
    }
  }
}

// --- MODÈLE DE DONNÉES ---

class MonthStats {
  final double sales;
  final double purchases;
  final double expenses;
  final double prevMonthSales;
  final double prevMonthPurchases;
  final double prevMonthExpenses;
  final DateTime selectedMonth;

  MonthStats({
    required this.sales,
    required this.purchases,
    required this.expenses,
    required this.prevMonthSales,
    required this.prevMonthPurchases,
    required this.prevMonthExpenses,
    required this.selectedMonth,
  });

  double get salesEvolution => _calculate(prevMonthSales, sales);
  double get purchasesEvolution => _calculate(prevMonthPurchases, purchases);
  double get expensesEvolution => _calculate(prevMonthExpenses, expenses);

  double _calculate(double prev, double curr) {
    if (prev == 0) return curr > 0 ? 100 : 0;
    return ((curr - prev) / prev) * 100;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }
}

// --- DIALOGUE DE SÉLECTION (À l'extérieur de la classe DashboardCard) ---

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _MonthYearPickerDialog({required this.initialDate});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int year;
  late int month;
  final List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];

  @override
  void initState() {
    super.initState();
    year = widget.initialDate.year;
    month = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Choisir le mois"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => year--), icon: const Icon(Icons.arrow_back_ios, size: 16)),
              Text("$year", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: () => setState(() => year++), icon: const Icon(Icons.arrow_forward_ios, size: 16)),
            ],
          ),
          const Divider(),
          SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 0,
              alignment: WrapAlignment.center,
              children: List.generate(12, (i) {
                return ChoiceChip(
                  label: Text(months[i]),
                  selected: month == i + 1,
                  onSelected: (selected) {
                    if (selected) setState(() => month = i + 1);
                  },
                );
              }),
            ),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, DateTime(year, month)), 
          child: const Text("Valider")
        ),
      ],
    );
  }
}
