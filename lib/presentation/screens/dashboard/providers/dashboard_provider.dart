import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';

// ==================== MODELS ====================

class DashboardStats {
  final double totalAchats;
  final double totalVentes;
  final double totalDepenses;
  final double marge;
  final List<MonthlyData> monthlyEvolution;
  final List<ProductSale> bestProducts;
  final List<ProductSale> worstProducts;
  final String period;

  DashboardStats({
    required this.totalAchats,
    required this.totalVentes,
    required this.totalDepenses,
    required this.marge,
    required this.monthlyEvolution,
    required this.bestProducts,
    required this.worstProducts,
    required this.period,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalAchats: 0,
      totalVentes: 0,
      totalDepenses: 0,
      marge: 0,
      monthlyEvolution: [],
      bestProducts: [],
      worstProducts: [],
      period: 'Mois',
    );
  }

  double get margePercent => totalVentes > 0 ? (marge / totalVentes) * 100 : 0;
  bool get isProfitable => marge >= 0;
}

class MonthlyData {
  final DateTime month;
  final double achats;
  final double ventes;
  final double depenses;

  MonthlyData({
    required this.month,
    required this.achats,
    required this.ventes,
    required this.depenses,
  });
}

class ProductSale {
  final String name;
  final double quantity;
  final double revenue;

  ProductSale({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

// ==================== PROVIDER ====================

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
      return DashboardNotifier();
    });

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final SupabaseClient supabase = Supabase.instance.client;

  DashboardNotifier() : super(const AsyncValue.loading()) {
    loadData('Mois');
  }

  Future<void> loadData(String period) async {
    state = const AsyncValue.loading();

    try {
      final now = DateTime.now();
      DateTime? start;
      DateTime end = now;

      switch (period) {
        case 'Semaine':
          start = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'Mois':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'Année':
          start = DateTime(now.year, 1, 1);
          break;
      }

      final stats = await _fetchStats(start, end, period);
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DashboardStats> _fetchStats(
    DateTime? start,
    DateTime end,
    String period,
  ) async {
    final achats = await _getTotal('purchases', 'purchase_date', start, end);
    final ventes = await _getTotal('sales', 'sale_date', start, end);
    final depenses = await _getTotal('expenses', 'expenses_date', start, end);

    final monthly = await _getMonthlyEvolution();
    final products = await _getProductStats(start, end);

    return DashboardStats(
      totalAchats: achats,
      totalVentes: ventes,
      totalDepenses: depenses,
      marge: ventes - achats - depenses,
      monthlyEvolution: monthly,
      bestProducts: products['best'] ?? [],
      worstProducts: products['worst'] ?? [],
      period: period,
    );
  }

  Future<double> _getTotal(
    String table,
    String dateCol,
    DateTime? start,
    DateTime? end,
  ) async {
    var query = supabase.from(table).select('amount');
    if (start != null) query = query.gte(dateCol, start.toIso8601String());
    if (end != null) query = query.lte(dateCol, end.toIso8601String());

    final res = await query;
    return (res as List).fold<double>(0.0, (sum, row) {
      return sum + ((row['amount'] as num?)?.toDouble() ?? 0.0);
    });
  }

  Future<List<MonthlyData>> _getMonthlyEvolution() async {
    final now = DateTime.now();
    final List<MonthlyData> data = [];

    for (int i = 11; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

      final achats = await _getTotal(
        'purchases',
        'purchase_date',
        monthStart,
        monthEnd,
      );
      final ventes = await _getTotal(
        'sales',
        'sale_date',
        monthStart,
        monthEnd,
      );
      final depenses = await _getTotal(
        'expenses',
        'expenses_date',
        monthStart,
        monthEnd,
      );

      data.add(
        MonthlyData(
          month: monthStart,
          achats: achats,
          ventes: ventes,
          depenses: depenses,
        ),
      );
    }
    return data;
  }

  Future<Map<String, List<ProductSale>>> _getProductStats(
    DateTime? start,
    DateTime? end,
  ) async {
    var query = supabase
        .from('sales')
        .select('product_id, quantity, amount, products!inner(name)');

    if (start != null) query = query.gte('sale_date', start.toIso8601String());
    if (end != null) query = query.lte('sale_date', end.toIso8601String());

    final res = await query;

    final Map<String, ProductSale> salesMap = {};

    for (final sale in res) {
      final name = (sale['products'] as Map?)?['name'] as String? ?? 'Inconnu';
      final qty = (sale['quantity'] as num?)?.toDouble() ?? 0.0;
      final amount = (sale['amount'] as num?)?.toDouble() ?? 0.0;

      final existing = salesMap[name];
      salesMap[name] = ProductSale(
        name: name,
        quantity: (existing?.quantity ?? 0) + qty,
        revenue: (existing?.revenue ?? 0) + amount,
      );
    }

    final sorted = salesMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return {
      'best': sorted.take(5).toList(),
      'worst': sorted.reversed.take(5).toList(),
    };
  }
}

// ==================== HELPERS ====================

String formatCFA(double amount) => Formatters.formatCurrency(amount);
String formatNumber(int number) => Formatters.formatNumber(number);
