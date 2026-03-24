import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'purchases/purchases_list_view.dart';
import 'purchases/purchases_dashboard_view.dart';
import 'purchases/purchases_add_form.dart';
import 'purchases/purchases_edit_form.dart';
import 'purchases/purchases_filter_sheet.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final supabase = Supabase.instance.client;

  // ───────────────────────────────────────────────
  // Variables d'état principales
  // ───────────────────────────────────────────────
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _products = [];
  String _selectedTab = 'Liste';
  String _selectedPeriod = 'Mois';
  String _productFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _exactQuantity;
  double _totalMoisActuel = 0;
  double _totalMoisPrecedent = 0;
  double _difference = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ───────────────────────────────────────────────
  // Chargement global
  // ───────────────────────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadPurchases(),
        _loadProducts(),
        _calculateMonthlyTotals(),
      ]);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement : $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPurchases() async {
    try {
      final data = await supabase
          .from('purchases')
          .select('*, products!inner(name)')
          .order('purchase_date', ascending: false);
      if (mounted) setState(() => _purchases = data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur achats : $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select('id, name, current_stock')
          .order('name');
      if (mounted) setState(() => _products = data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur produits : $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _calculateMonthlyTotals() async {
    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = DateTime(now.year, now.month, 0);

      _totalMoisActuel = await _getTotal(
        'purchases',
        'purchase_date',
        currentMonthStart,
        currentMonthEnd,
      );
      _totalMoisPrecedent = await _getTotal(
        'purchases',
        'purchase_date',
        prevMonthStart,
        prevMonthEnd,
      );
      _difference = _totalMoisActuel - _totalMoisPrecedent;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur totaux : $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<double> _getTotal(
    String table,
    String dateColumn,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final res = await supabase
          .from(table)
          .select('amount')
          .gte(dateColumn, start.toIso8601String())
          .lte(dateColumn, end.toIso8601String());
      return res.fold<double>(
        0.0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (_) {
      return 0.0;
    }
  }

  // ───────────────────────────────────────────────
  // Filtrage local
  // ───────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPurchases {
    var list = List<Map<String, dynamic>>.from(_purchases);

    final now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd = now.add(const Duration(days: 1));

    switch (_selectedPeriod) {
      case 'Semaine':
        periodStart = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Mois':
        periodStart = DateTime(now.year, now.month, 1);
        break;
      default:
        periodStart = DateTime(now.year, 1, 1);
    }

    list = list.where((p) {
      final dateStr = p['purchase_date'] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          date.isBefore(periodEnd);
    }).toList();

    if (_productFilter.isNotEmpty) {
      final q = _productFilter.toLowerCase();
      list = list.where((p) {
        final name = p['products']?['name'] as String?;
        return name != null && name.toLowerCase().contains(q);
      }).toList();
    }

    if (_startDate != null || _endDate != null) {
      list = list.where((p) {
        final date = DateTime.tryParse(p['purchase_date'] ?? '');
        if (date == null) return false;
        if (_startDate != null && date.isBefore(_startDate!)) return false;
        if (_endDate != null && date.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    if (_exactQuantity != null) {
      list = list
          .where((p) => (p['quantity'] as int?) == _exactQuantity)
          .toList();
    }

    list.sort((a, b) {
      final da = DateTime.tryParse(a['purchase_date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['purchase_date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return list;
  }

  Map<String, Map<String, num>> _getMonthlyTotalsWithDiff() {
    final map = <String, Map<String, num>>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    for (var p in _purchases) {
      final dateStr = p['purchase_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = fmt.format(date);
      map.putIfAbsent(key, () => {'amount': 0, 'diff': 0});
      map[key]!['amount'] = (map[key]!['amount']! + (p['amount'] as num? ?? 0));
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => fmt.parse(b).compareTo(fmt.parse(a)));

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final current = map[sortedKeys[i]]!['amount']!;
      final previous = map[sortedKeys[i + 1]]!['amount']!;
      map[sortedKeys[i]]!['diff'] = current - previous;
    }

    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, map[key]!)));
  }

  // ───────────────────────────────────────────────
  // UI globale
  // ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = _filteredPurchases.fold<num>(
      0,
      (sum, item) => sum + (item['amount'] as num? ?? 0),
    );
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achats'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
              ),
              child: Icon(
                Icons.filter_list,
                color: Colors.blue.shade700,
                size: 22,
              ),
            ),
            onPressed: () => showPurchasesFilterSheet(
              context,
              onFilterChanged: (filter, start, end, qty) {
                setState(() {
                  _productFilter = filter;
                  _startDate = start;
                  _endDate = end;
                  _exactQuantity = qty;
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabButton('Liste', _selectedTab == 'Liste'),
                      _buildTabButton('Dashboard', _selectedTab == 'Dashboard'),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedTab == 'Liste'
                      ? PurchasesListView(
                          purchases: _filteredPurchases,
                          total: total,
                          isSmall: isSmall,
                          onEdit: (purchase) => showEditPurchaseForm(
                            context,
                            purchase: purchase,
                            products: _products,
                            onUpdated: _loadData,
                          ),
                          onDelete: _deletePurchase,
                        )
                      : PurchasesDashboardView(
                          totalMoisActuel: _totalMoisActuel,
                          difference: _difference,
                          monthlyTotals: _getMonthlyTotalsWithDiff(),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        mini: isSmall,
        backgroundColor: Colors.blue.shade700,
        onPressed: () => showAddPurchaseForm(
          context,
          products: _products,
          onAdded: _loadData,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Suppression achat (définie ici pour éviter l'erreur Undefined name)
  // ───────────────────────────────────────────────

  void _deletePurchase(Map<String, dynamic> purchase) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer achat ?'),
        content: const Text('Cette action ajustera le stock. Confirmer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final qty = purchase['quantity'] as int;
                final prodId = purchase['product_id'];
                await supabase
                    .from('purchases')
                    .delete()
                    .eq('id', purchase['id']);
                // Ajustement stock (exemple simple – adapte selon ta logique réelle)
                await supabase.rpc(
                  'update_stock_after_delete',
                  params: {'p_product_id': prodId, 'p_quantity': qty},
                );
                if (mounted) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Achat supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur suppression : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
