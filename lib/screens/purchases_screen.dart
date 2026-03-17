import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/core/services/supabase_service.dart';
import 'package:facil_count_nouveau/core/widgets/compact_card.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // --- 1. Initialisation ---
  final _api = SupabaseService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
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
        _loadPurchases(),
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

  Future<void> _loadPurchases() async {
    try {
      final data = await _api.getPurchases();
      setState(() => _purchases = data);
    } catch (e) {
      throw Exception('Erreur achats: ${e.toString()}');
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
      'purchases',
      'purchase_date',
      firstDayOfMonth,
      lastDayOfMonth,
    );
    _totalMoisPrecedent = await _getTotal(
      'purchases',
      'purchase_date',
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
      default: // Année
        periodStart = DateTime(now.year, 1, 1);
    }

    list = list.where((p) {
      final dateStr = p['purchase_date'] as String?;
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
            (p) =>
                (p['products']?['name'] as String?)?.toLowerCase().contains(
                  q,
                ) ??
                false,
          )
          .toList();
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
  String _formatCFA(num amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.abs())} F CFA';
  }

  Color _getDiffColor(double diff) {
    if (diff > 0) return Colors.green.shade700;
    if (diff < 0) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  Map<String, Map<String, num>> _getMonthlyTotalsWithDiff() {
    final map = <String, Map<String, num>>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    // Utiliser un Set pour éviter les doublons
    final uniqueEntries = <String>{};

    for (var p in _purchases) {
      final dateStr = p['purchase_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = fmt.format(date);

      // Vérifier si la clé est déjà présente
      if (!uniqueEntries.contains(key)) {
        uniqueEntries.add(key);
        map[key] = {'amount': 0, 'diff': 0};
      }

      map[key]!['amount'] =
          (map[key]!['amount']! + (p['amount'] as num? ?? 0)) as num;
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
    final total = _filteredPurchases.fold<num>(
      0,
      (sum, item) => sum + (item['amount'] as num? ?? 0),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

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
                  Expanded(child: _buildPurchasesList()),
                ] else ...[
                  Expanded(child: _buildCompactAnnualDashboard()),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        mini: isSmall,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
        onPressed: _showAddPurchaseForm,
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

  Widget _buildTotalCard(num total, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total achats',
                style: TextStyle(fontSize: isSmall ? 15 : 17),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatCFA(total),
                  style: TextStyle(
                    fontSize: isSmall ? 17 : 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
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
                selectedColor: Colors.blue.shade700,
                backgroundColor: Colors.grey.shade200,
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

  Widget _buildPurchasesList() {
    final displayedList = _filteredPurchases;
    if (displayedList.isEmpty) {
      return const Center(child: Text('Aucun achat trouvé'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: displayedList.length,
      itemBuilder: (context, index) {
        final p = displayedList[index];
        final name = p['products']?['name'] as String? ?? 'Inconnu';
        final amount = p['amount'] as num? ?? 0.0;
        final qty = p['quantity'] as num? ?? 0;
        final locked = p['locked'] == true;
        return _buildPurchaseCard(p, name, amount, qty, locked);
      },
    );
  }

  Widget _buildPurchaseCard(
    Map<String, dynamic> p,
    String name,
    num amount,
    num qty,
    bool locked,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                qty.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildPurchaseInfo(p, name)),
            SizedBox(
              width: 140,
              child: _buildPurchaseActions(p, amount, qty, locked),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseInfo(Map<String, dynamic> p, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          p['purchase_date']?.substring(0, 10) ?? '',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPurchaseActions(
    Map<String, dynamic> p,
    num amount,
    num qty,
    bool locked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatCFA(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        Text(
          '$qty ×',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 18,
              color: locked ? Colors.yellow.shade800 : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue.shade700,
              onPressed: () => _showEditPurchaseDialog(p),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red.shade700,
              onPressed: () => _deletePurchase(p),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactAnnualDashboard() {
    final monthlyTotals = _getMonthlyTotalsWithDiff();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Carte pour le total des achats du mois
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFE3F2FD),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Achats du mois',
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
                        color: const Color(0xFF1565C0),
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

          const SizedBox(height: 16),

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
              backgroundColor: const Color(0xFFE3F2FD),
            );
          }).toList(),
        ],
      ),
    );
  }

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
                'Filtrer les achats',
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
                      backgroundColor: Colors.red.shade700,
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

  // --- Méthodes pour les dialogues d'ajout/modification/suppression ---
  Future<void> _showAddPurchaseForm() async {
    String? selectedProductId;
    final invoiceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    DateTime purchaseDate = DateTime.now();
    bool paid = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un achat'),
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
                      controller: invoiceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Numéro facture (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(purchaseDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => purchaseDate = picked),
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
                        labelText: 'Montant total payé *',
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
                    TextField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur (optionnel)',
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
                  onPressed: () => _handleAddPurchaseSubmit(
                    dialogContext: dialogContext,
                    selectedProductId: selectedProductId,
                    invoiceCtrl: invoiceCtrl,
                    quantityCtrl: quantityCtrl,
                    amountCtrl: amountCtrl,
                    supplierCtrl: supplierCtrl,
                    purchaseDate: purchaseDate,
                    paid: paid,
                  ),
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPurchaseDialog(Map<String, dynamic> purchase) async {
    String? selectedProductId = purchase['product_id'];
    final invoiceCtrl = TextEditingController(
      text: purchase['invoice_number'] ?? '',
    );
    final quantityCtrl = TextEditingController(
      text: purchase['quantity'].toString(),
    );
    final amountCtrl = TextEditingController(
      text: purchase['amount'].toString(),
    );
    final supplierCtrl = TextEditingController(
      text: purchase['supplier'] ?? '',
    );
    DateTime purchaseDate =
        DateTime.tryParse(purchase['purchase_date'] ?? '') ?? DateTime.now();
    bool paid = purchase['paid'] ?? true;
    bool locked = purchase['locked'] ?? false;
    final oldProductId = purchase['product_id'];
    final oldQuantity = purchase['quantity'] as int;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier achat'),
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
                          return const Text('Aucun produit');
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
                      controller: invoiceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Numéro facture (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(purchaseDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => purchaseDate = picked),
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
                        labelText: 'Montant total payé *',
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
                    TextField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur (optionnel)',
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
                  onPressed: () => _handleEditPurchaseSubmit(
                    dialogContext: dialogContext,
                    purchase: purchase,
                    selectedProductId: selectedProductId,
                    oldProductId: oldProductId,
                    oldQuantity: oldQuantity,
                    invoiceCtrl: invoiceCtrl,
                    quantityCtrl: quantityCtrl,
                    amountCtrl: amountCtrl,
                    supplierCtrl: supplierCtrl,
                    purchaseDate: purchaseDate,
                    paid: paid,
                    locked: locked,
                  ),
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePurchase(Map<String, dynamic> purchase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer achat ?'),
        content: Text(
          'Voulez-vous supprimer cet achat du ${purchase['purchase_date']?.substring(0, 10) ?? 'date inconnue'} ?',
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
      final productId = purchase['product_id'];
      final quantity = purchase['quantity'] as int;

      await _supabase.from('purchases').delete().eq('id', purchase['id']);
      await _updateProductStock(productId, -quantity);

      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat supprimé et stock ajusté')),
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
            value: prod['id'] as String,
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

  Future<void> _handleAddPurchaseSubmit({
    required BuildContext dialogContext,
    required String? selectedProductId,
    required TextEditingController invoiceCtrl,
    required TextEditingController quantityCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController supplierCtrl,
    required DateTime purchaseDate,
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

      await _supabase.from('purchases').insert({
        'product_id': selectedProductId,
        'invoice_number': invoiceCtrl.text.trim().isEmpty
            ? null
            : invoiceCtrl.text.trim(),
        'purchase_date': purchaseDate.toIso8601String(),
        'quantity': quantity,
        'amount': amount,
        'supplier': supplierCtrl.text.trim().isEmpty
            ? null
            : supplierCtrl.text.trim(),
        'paid': paid,
        'locked': false,
      });

      await _updateProductStock(selectedProductId, quantity);

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat ajouté et stock mis à jour')),
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

  Future<void> _handleEditPurchaseSubmit({
    required BuildContext dialogContext,
    required Map<String, dynamic> purchase,
    required String? selectedProductId,
    required String oldProductId,
    required int oldQuantity,
    required TextEditingController invoiceCtrl,
    required TextEditingController quantityCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController supplierCtrl,
    required DateTime purchaseDate,
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

      await _supabase
          .from('purchases')
          .update({
            'product_id': selectedProductId,
            'invoice_number': invoiceCtrl.text.trim().isEmpty
                ? null
                : invoiceCtrl.text.trim(),
            'purchase_date': purchaseDate.toIso8601String(),
            'quantity': quantity,
            'amount': amount,
            'supplier': supplierCtrl.text.trim().isEmpty
                ? null
                : supplierCtrl.text.trim(),
            'paid': paid,
            'locked': locked,
          })
          .eq('id', purchase['id']);

      if (selectedProductId != oldProductId) {
        await _updateProductStock(oldProductId, -oldQuantity);
        await _updateProductStock(selectedProductId!, quantity);
      } else {
        final quantityDiff = quantity - oldQuantity;
        if (quantityDiff != 0) {
          await _updateProductStock(selectedProductId!, quantityDiff);
        }
      }

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achat modifié et stock ajusté')),
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
