import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/core/constants/app_colors.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';
import 'package:facil_count_nouveau/core/widgets/compact_card.dart';
import 'package:facil_count_nouveau/core/services/supabase_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // --- 1. Initialisation ---
  final _api = SupabaseService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _products = [];
  String _selectedPeriod = 'Mois';
  String _selectedTab = 'Liste';
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSales(),
        _loadProducts(),
        _calculateMonthlyTotals(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSales() async {
    try {
      final data = await _api.getSales();
      setState(() => _sales = data);
    } catch (e) {
      throw Exception('Erreur ventes: ${e.toString()}');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _supabase.from('products').select('id, name, stock');
      setState(() => _products = data);
    } catch (e) {
      throw Exception('Erreur produits: ${e.toString()}');
    }
  }

  Future<void> _calculateMonthlyTotals() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);

    _totalMoisActuel = await _getTotal(
      'sales',
      'sale_date',
      firstDayOfMonth,
      lastDayOfMonth,
    );
    _totalMoisPrecedent = await _getTotal(
      'sales',
      'sale_date',
      firstDayOfPreviousMonth,
      lastDayOfPreviousMonth,
    );
    _difference = _totalMoisActuel - _totalMoisPrecedent;
  }

  Future<double> _getTotal(
    String table,
    String dateColumn,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final res = await _supabase
          .from(table)
          .select('amount')
          .gte(dateColumn, start.toIso8601String())
          .lte(dateColumn, end.toIso8601String());

      return res.fold<double>(
        0.0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e) {
      return 0.0;
    }
  }

  // --- 2. Logique de filtrage ---
  List<Map<String, dynamic>> get _filteredSales {
    var list = List<Map<String, dynamic>>.from(_sales);
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
      default: // Année
        periodStart = DateTime(now.year, 1, 1);
    }

    list = list.where((s) {
      final dateStr = s['sale_date'] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      return date != null &&
          date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          date.isBefore(periodEnd);
    }).toList();

    if (_productFilter.isNotEmpty) {
      final q = _productFilter.toLowerCase();
      list = list
          .where(
            (s) =>
                (s['products']?['name'] as String?)?.toLowerCase().contains(
                  q,
                ) ??
                false,
          )
          .toList();
    }

    if (_startDate != null || _endDate != null) {
      list = list.where((s) {
        final date = DateTime.tryParse(s['sale_date'] ?? '');
        if (date == null) return false;
        if (_startDate != null && date.isBefore(_startDate!)) return false;
        if (_endDate != null && date.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    if (_exactQuantity != null) {
      list = list
          .where((s) => (s['quantity'] as int?) == _exactQuantity)
          .toList();
    }

    list.sort((a, b) {
      final da = DateTime.tryParse(a['sale_date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['sale_date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return list;
  }

  // --- 3. Gestion du stock ---
  Future<void> _updateProductStock(String productId, int quantityChange) async {
    try {
      final productRes = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();
      final currentStock = (productRes['stock'] as int?) ?? 0;
      await _supabase
          .from('products')
          .update({'stock': currentStock + quantityChange})
          .eq('id', productId);
    } catch (e) {
      throw Exception('Erreur mise à jour stock: ${e.toString()}');
    }
  }

  // --- 4. UI Helpers ---
  Color _getDiffColor(double diff) {
    if (diff > 0) return AppColors.salesAccent;
    if (diff < 0) return AppColors.error;
    return AppColors.neutral;
  }

  Map<String, Map<String, num>> _getMonthlyTotalsWithDiff() {
    final map = <String, Map<String, num>>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    for (var s in _sales) {
      final dateStr = s['sale_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = fmt.format(date);
      map.putIfAbsent(key, () => {'amount': 0, 'diff': 0});
      map[key]!['amount'] =
          (map[key]!['amount']! + (s['amount'] as num? ?? 0)) as num;
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => fmt.parse(b).compareTo(fmt.parse(a)));

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final current = map[sortedKeys[i]]!['amount']! as num;
      final previous = map[sortedKeys[i + 1]]!['amount']! as num;
      map[sortedKeys[i]]!['diff'] = (current - previous) as num;
    }

    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, map[key]!)));
  }

  // --- 5. UI Build ---
  @override
  Widget build(BuildContext context) {
    final total = _filteredSales.fold<num>(
      0,
      (sum, item) => sum + (item['amount'] as num? ?? 0),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.salesLight,
              ),
              child: Icon(
                Icons.filter_list,
                color: AppColors.salesAccent,
                size: 22,
              ),
            ),
            onPressed: _showFilterBottomSheet,
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
                      _buildTabButton(
                        'Dashboard annuel',
                        _selectedTab == 'Dashboard annuel',
                      ),
                    ],
                  ),
                ),
                if (_selectedTab == 'Liste') ...[
                  _buildTotalCard(total, isSmall),
                  _buildPeriodFilterChips(),
                  Expanded(child: _buildSalesList()),
                ] else ...[
                  Expanded(child: _buildCompactAnnualDashboard()),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        mini: isSmall,
        backgroundColor: AppColors.salesAccent,
        child: const Icon(Icons.add),
        onPressed: _showAddSaleForm,
      ),
    );
  }

  // --- Widgets UI ---
  Widget _buildTabButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.salesAccent : Colors.transparent,
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

  Widget _buildTotalCard(num total, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Total ventes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCFA(total),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semaine', 'Mois', 'Année'].map((p) {
            final sel = p == _selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(p, style: const TextStyle(fontSize: 13)),
                selected: sel,
                onSelected: (v) => setState(() => _selectedPeriod = p),
                selectedColor: AppColors.salesAccent,
                backgroundColor: AppColors.greyLight,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                ),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    final displayedList = _filteredSales;
    if (displayedList.isEmpty) {
      return const Center(child: Text('Aucune vente trouvée'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: displayedList.length,
      itemBuilder: (context, index) {
        final s = displayedList[index];
        final name = s['products']?['name'] as String? ?? 'Inconnu';
        final amount = s['amount'] as num? ?? 0.0;
        final qty = s['quantity'] as num? ?? 0;
        final locked = s['locked'] == true;
        return CompactSaleCard(
          productName: name,
          amount: amount.toDouble(),
          quantity: qty.toInt(),
          date: s['sale_date']?.substring(0, 10) ?? '',
          isLocked: locked,
          onEdit: () => _showEditSaleDialog(s),
          onDelete: () => _deleteSale(s),
        );
      },
    );
  }

  Widget _buildCompactAnnualDashboard() {
    final monthlyTotals = _getMonthlyTotalsWithDiff();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Carte pour le total des ventes du mois
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Ventes du mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCFA(_totalMoisActuel),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _difference >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: _getDiffColor(_difference),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatCFA(_difference.abs())} vs mois préc.',
                        style: TextStyle(
                          fontSize: 15,
                          color: _getDiffColor(_difference),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnnualDashboardCard(
            month: "mars 2026",
            amount: 123400.0,
            previousAmount: 10000.0,
            isIncrease: true,
            amountColor: const Color(0xFF2E7D32), // Vert foncé
            backgroundColor: const Color(0xFFE8F5E9), // Vert clair
          ),

          const SizedBox(height: 24),

          // Cartes mensuelles avec AnnualDashboardCard
          ...monthlyTotals.entries.map((entry) {
            final month = entry.key;
            final amount = entry.value['amount'] as num;
            final diff = entry.value['diff'] as num;
            final isIncrease = diff >= 0;
            final diffColor = _getDiffColor(diff.toDouble());

            return AnnualDashboardCard(
              month: month.toUpperCase(),
              amount: amount.toDouble(),
              previousAmount: (amount - diff).toDouble(),
              isIncrease: isIncrease,
              amountColor: diffColor,
              backgroundColor: Colors.green[50]!,
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- Dialogues ---
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheetContent(context),
    );
  }

  Widget _buildFilterBottomSheetContent(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrer les ventes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nom du produit (contient)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() => _productFilter = val.trim());
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerButton(
                      context: context,
                      label: _startDate == null
                          ? 'Date début'
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                      onDateSelected: (picked) {
                        setState(() => _startDate = picked);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDatePickerButton(
                      context: context,
                      label: _endDate == null
                          ? 'Date fin'
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                      onDateSelected: (picked) {
                        setState(() => _endDate = picked);
                        setModalState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Quantité exacte',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  _exactQuantity = int.tryParse(val.trim());
                  setState(() {});
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () {
                      setState(() {
                        _productFilter = '';
                        _startDate = null;
                        _endDate = null;
                        _exactQuantity = null;
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Text(label),
    );
  }

  Widget _buildProductDropdown({
    required List<Map<String, dynamic>> products,
    required String? selectedProductId,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: selectedProductId,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: const InputDecoration(
          labelText: 'Produit / Service *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: products.map((prod) {
          final stock = prod['stock'] as int? ?? 0;
          return DropdownMenuItem<String>(
            value: prod['id'].toString(),
            child: Text(
              '${prod['name']} (stock: $stock)',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // --- Méthodes pour les dialogues d'ajout/modification/suppression ---
  Future<void> _showAddSaleForm() async {
    String? selectedProductId;
    final quantityCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    DateTime saleDate = DateTime.now();
    bool paid = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter une vente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _supabase
                          .from('products')
                          .select('id, name, stock')
                          .order('name'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Aucun produit disponible');
                        }
                        return _buildProductDropdown(
                          products: snapshot.data!,
                          selectedProductId: selectedProductId,
                          onChanged: (val) =>
                              setDialogState(() => selectedProductId = val),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantité *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant total (CFA) *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                        helperText: 'Utilisez le point (.) pour les décimales',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(
                              offset: cleaned.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(saleDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => saleDate = picked),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payé (cash)'),
                      value: paid,
                      onChanged: (val) => setDialogState(() => paid = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => _handleAddSaleSubmit(
                    dialogContext: dialogContext,
                    selectedProductId: selectedProductId,
                    quantityCtrl: quantityCtrl,
                    amountCtrl: amountCtrl,
                    customerCtrl: customerCtrl,
                    saleDate: saleDate,
                    paid: paid,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSaleDialog(Map<String, dynamic> sale) async {
    String? selectedProductId = sale['product_id'].toString();
    final quantityCtrl = TextEditingController(
      text: sale['quantity'].toString(),
    );
    final amountCtrl = TextEditingController(text: sale['amount'].toString());
    final customerCtrl = TextEditingController(text: sale['customer'] ?? '');
    DateTime saleDate =
        DateTime.tryParse(sale['sale_date'] ?? '') ?? DateTime.now();
    bool paid = sale['paid'] ?? true;
    bool locked = sale['locked'] ?? false;
    final oldQuantity = sale['quantity'] as int? ?? 0;
    final oldProductId = sale['product_id'].toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier vente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _supabase
                          .from('products')
                          .select('id, name, stock')
                          .order('name'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Aucun produit disponible');
                        }
                        return _buildProductDropdown(
                          products: snapshot.data!,
                          selectedProductId: selectedProductId,
                          onChanged: (val) =>
                              setDialogState(() => selectedProductId = val),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantité *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant total (CFA) *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                        helperText: 'Utilisez le point (.) pour les décimales',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(
                              offset: cleaned.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(saleDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => saleDate = picked),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payé (cash)'),
                      value: paid,
                      onChanged: (val) => setDialogState(() => paid = val),
                    ),
                    SwitchListTile(
                      title: const Text('Verrouillé'),
                      value: locked,
                      onChanged: (val) => setDialogState(() => locked = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => _handleEditSaleSubmit(
                    dialogContext: dialogContext,
                    sale: sale,
                    selectedProductId: selectedProductId,
                    oldProductId: oldProductId,
                    oldQuantity: oldQuantity,
                    quantityCtrl: quantityCtrl,
                    amountCtrl: amountCtrl,
                    customerCtrl: customerCtrl,
                    saleDate: saleDate,
                    paid: paid,
                    locked: locked,
                  ),
                  child: const Text('Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSale(Map<String, dynamic> sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer vente ?'),
        content: Text(
          'Voulez-vous supprimer cette vente du ${sale['sale_date']?.substring(0, 10) ?? 'date inconnue'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final quantity = sale['quantity'] as int? ?? 0;
      final productId = sale['product_id'].toString();

      await _supabase.from('sales').delete().eq('id', sale['id']);
      await _updateProductStock(productId, quantity);

      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente supprimée et stock remis')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : ${e.toString()}')),
        );
      }
    }
  }

  // --- Logique de soumission ---
  Future<void> _handleAddSaleSubmit({
    required BuildContext dialogContext,
    required String? selectedProductId,
    required TextEditingController quantityCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController customerCtrl,
    required DateTime saleDate,
    required bool paid,
  }) async {
    if (selectedProductId == null ||
        quantityCtrl.text.trim().isEmpty ||
        amountCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit, quantité et montant obligatoires'),
          ),
        );
      }
      return;
    }

    try {
      final quantity = int.parse(quantityCtrl.text.trim());
      final montantText = amountCtrl.text
          .trim()
          .replaceAll(',', '.')
          .replaceAll(' ', '');
      final amount = double.tryParse(montantText) ?? 0.0;

      if (amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Montant invalide (ex. 375000 ou 375.50)'),
            ),
          );
        }
        return;
      }

      final productRes = await _supabase
          .from('products')
          .select('stock')
          .eq('id', selectedProductId)
          .single();
      final currentStock = (productRes['stock'] as int?) ?? 0;

      if (quantity > currentStock) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock insuffisant ! Disponible : $currentStock'),
            ),
          );
        }
        return;
      }

      await _supabase.from('sales').insert({
        'product_id': selectedProductId,
        'quantity': quantity,
        'amount': amount,
        'sale_date': saleDate.toIso8601String(),
        'customer': customerCtrl.text.trim().isEmpty
            ? null
            : customerCtrl.text.trim(),
        'paid': paid,
        'locked': false,
      });

      await _updateProductStock(selectedProductId, -quantity);

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente ajoutée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ajout : ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleEditSaleSubmit({
    required BuildContext dialogContext,
    required Map<String, dynamic> sale,
    required String? selectedProductId,
    required String oldProductId,
    required int oldQuantity,
    required TextEditingController quantityCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController customerCtrl,
    required DateTime saleDate,
    required bool paid,
    required bool locked,
  }) async {
    if (selectedProductId == null ||
        quantityCtrl.text.trim().isEmpty ||
        amountCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit, quantité et montant obligatoires'),
          ),
        );
      }
      return;
    }

    try {
      final quantity = int.parse(quantityCtrl.text.trim());
      final montantText = amountCtrl.text
          .trim()
          .replaceAll(',', '.')
          .replaceAll(' ', '');
      final amount = double.tryParse(montantText) ?? 0.0;

      if (amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Montant invalide (ex. 375000 ou 375.50)'),
            ),
          );
        }
        return;
      }

      // Restaurer l'ancien stock si le produit a changé
      if (oldProductId != selectedProductId) {
        final oldProductRes = await _supabase
            .from('products')
            .select('stock')
            .eq('id', oldProductId)
            .single();
        final oldCurrentStock = (oldProductRes['stock'] as int?) ?? 0;
        await _supabase
            .from('products')
            .update({'stock': oldCurrentStock + oldQuantity})
            .eq('id', oldProductId);
      }

      // Vérifier le stock pour le nouveau produit
      final productRes = await _supabase
          .from('products')
          .select('stock')
          .eq('id', selectedProductId)
          .single();
      final currentStock = (productRes['stock'] as int?) ?? 0;
      final adjustedStock =
          (oldProductId == selectedProductId
              ? currentStock + oldQuantity
              : currentStock) -
          quantity;

      if (adjustedStock < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Stock insuffisant après ajustement ! Disponible : ${currentStock + (oldProductId == selectedProductId ? oldQuantity : 0)}',
              ),
            ),
          );
        }
        return;
      }

      await _supabase
          .from('sales')
          .update({
            'product_id': selectedProductId,
            'quantity': quantity,
            'amount': amount,
            'sale_date': saleDate.toIso8601String(),
            'customer': customerCtrl.text.trim().isEmpty
                ? null
                : customerCtrl.text.trim(),
            'paid': paid,
            'locked': locked,
          })
          .eq('id', sale['id']);

      await _updateProductStock(selectedProductId, -quantity);

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente modifiée et stock ajusté')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur modification : ${e.toString()}')),
        );
      }
    }
  }
}
