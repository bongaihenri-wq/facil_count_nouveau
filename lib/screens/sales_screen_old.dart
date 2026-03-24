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
  // 1. Variables d'état
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

  // 2. Méthodes de chargement
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
      if (mounted) setState(() => _sales = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement ventes: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('id, name, stock, low_stock_threshold')
          .order('name');
      if (mounted) setState(() => _products = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement produits: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // 3. Méthodes de calcul
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

  // 4. Méthode de mise à jour du stock
  Future<void> _updateProductStock(String productId, int quantityChange) async {
    try {
      final stockRes = await _supabase
          .from('product_current_stock')
          .select('current_stock')
          .eq('id', productId)
          .maybeSingle();

      final currentStock = (stockRes?['current_stock'] as int?) ?? 0;
      final newStock = currentStock + quantityChange;

      if (newStock < 0) {
        throw Exception('Stock insuffisant');
      }

      await _supabase.from('product_current_stock').upsert({
        'id': productId,
        'current_stock': newStock,
        'last_updated': DateTime.now().toIso8601String(),
      }).select();
    } catch (e) {
      throw Exception('Erreur mise à jour stock: ${e.toString()}');
    }
  }

  // 5. Méthodes d'UI réutilisables
  Widget _buildProductDropdown({
    required List<Map<String, dynamic>> products,
    required Map<String, dynamic>? selectedProduct,
    required ValueChanged<Map<String, dynamic>?> onChanged,
  }) {
    return DropdownButtonFormField<Map<String, dynamic>?>(
      value: selectedProduct,
      items: products.map((product) {
        final currentStock =
            product['current_stock']?['current_stock'] ?? product['stock'] ?? 0;
        return DropdownMenuItem<Map<String, dynamic>>(
          value: product,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: product['name'] ?? 'Inconnu',
                  style: const TextStyle(color: Colors.black),
                ),
                const TextSpan(text: ' - '),
                TextSpan(
                  text: 'Stock: $currentStock',
                  style: TextStyle(
                    color: currentStock > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Produit *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Sélectionnez un produit'),
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Text(label),
    );
  }

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
        return CompactSaleCard(
          productName: s['products']?['name'] ?? 'Inconnu',
          amount: (s['amount'] as num? ?? 0).toDouble(),
          quantity: s['quantity'] as int? ?? 0,
          date: s['sale_date']?.substring(0, 10) ?? '',
          isLocked: s['locked'] == true,
          onEdit: () => _showEditSaleDialog(s),
          onDelete: () => _deleteSale(s),
        );
      },
    );
  }

  Widget _buildCompactAnnualDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                        color: _difference >= 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatCFA(_difference.abs())} vs mois préc.',
                        style: TextStyle(
                          fontSize: 15,
                          color: _difference >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Filtrage des ventes
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

  // 7. Dialogue d'ajout de vente
  Future<void> _showAddSaleForm() async {
    final quantityCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    Map<String, dynamic>? selectedProduct;
    DateTime saleDate = DateTime.now();
    bool paid = true;
    bool isLoading = true;
    List<Map<String, dynamic>> products = [];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadProducts() async {
              setState(() => isLoading = true);
              try {
                final data = await _supabase
                    .from('products')
                    .select('''
                      id,
                      name,
                      stock,
                      current_stock:product_current_stock(current_stock)
                    ''')
                    .order('name');
                setState(() {
                  products = data;
                  isLoading = false;
                });
              } catch (e) {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur chargement produits: $e')),
                );
              }
            }

            WidgetsBinding.instance.addPostFrameCallback((_) => loadProducts());

            return AlertDialog(
              title: const Text('Ajouter une vente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildProductDropdown(
                        products: products,
                        selectedProduct: selectedProduct,
                        onChanged: (value) =>
                            setState(() => selectedProduct = value),
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
                    _buildDatePickerButton(
                      context: context,
                      label:
                          'Date: ${DateFormat('dd/MM/yyyy').format(saleDate)}',
                      onDateSelected: (picked) =>
                          setState(() => saleDate = picked),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant total (CFA) *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
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
                      onChanged: (val) => setState(() => paid = val),
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
                  onPressed: () async {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez sélectionner un produit'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final quantity =
                        int.tryParse(quantityCtrl.text.trim()) ?? 0;
                    final totalAmount =
                        double.tryParse(
                          amountCtrl.text.trim().replaceAll(',', '.'),
                        ) ??
                        0.0;

                    if (quantity <= 0 || totalAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Quantité et montant doivent être valides',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final currentStock =
                          selectedProduct!['current_stock']?['current_stock'] ??
                          selectedProduct!['stock'] ??
                          0;

                      if (quantity > currentStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Stock insuffisant (Disponible: $currentStock)',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      await _supabase.rpc(
                        'create_sale_with_stock_update',
                        params: {
                          'p_product_id': selectedProduct!['id'],
                          'p_quantity': quantity,
                          'p_total_price': totalAmount,
                          'p_sale_date': saleDate.toIso8601String(),
                          'p_client': customerCtrl.text.trim().isEmpty
                              ? null
                              : customerCtrl.text.trim(),
                        },
                      );

                      if (mounted) {
                        await _loadData();
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vente enregistrée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 8. Dialogue d'édition de vente
  Future<void> _showEditSaleDialog(Map<String, dynamic> sale) async {
    Map<String, dynamic>? selectedProduct;
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

    try {
      selectedProduct = await _supabase
          .from('products')
          .select()
          .eq('id', oldProductId)
          .maybeSingle();
    } catch (e) {
      selectedProduct = null;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          selectedProduct: selectedProduct,
                          onChanged: (value) =>
                              setState(() => selectedProduct = value),
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
                    _buildDatePickerButton(
                      context: context,
                      label:
                          'Date: ${DateFormat('dd/MM/yyyy').format(saleDate)}',
                      onDateSelected: (picked) =>
                          setState(() => saleDate = picked),
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
                      onChanged: (val) => setState(() => paid = val),
                    ),
                    SwitchListTile(
                      title: const Text('Verrouillé'),
                      value: locked,
                      onChanged: (val) => setState(() => locked = val),
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
                  onPressed: () async {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez sélectionner un produit'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Montant invalide (ex. 375000 ou 375.50)',
                            ),
                          ),
                        );
                        return;
                      }

                      if (oldProductId != selectedProduct!['id']) {
                        final oldProductRes = await _supabase
                            .from('products')
                            .select('stock')
                            .eq('id', oldProductId)
                            .single();
                        final oldCurrentStock =
                            (oldProductRes['stock'] as int?) ?? 0;
                        await _supabase
                            .from('products')
                            .update({'stock': oldCurrentStock + oldQuantity})
                            .eq('id', oldProductId);
                      }

                      final productRes = await _supabase
                          .from('products')
                          .select('stock')
                          .eq('id', selectedProduct!['id'])
                          .single();
                      final currentStock = (productRes['stock'] as int?) ?? 0;
                      final adjustedStock =
                          (oldProductId == selectedProduct!['id']
                              ? currentStock + oldQuantity
                              : currentStock) -
                          quantity;

                      if (adjustedStock < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Stock insuffisant après ajustement ! Disponible : ${currentStock + (oldProductId == selectedProduct!['id'] ? oldQuantity : 0)}',
                            ),
                          ),
                        );
                        return;
                      }

                      await _supabase
                          .from('sales')
                          .update({
                            'product_id': selectedProduct!['id'],
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

                      await _updateProductStock(
                        selectedProduct!['id'],
                        -quantity,
                      );

                      if (mounted) {
                        await _loadData();
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vente modifiée et stock ajusté'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur modification : ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 9. Suppression de vente
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

  // 10. Méthode build principale
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
            onPressed: () {
              // Implémentation du filtre si nécessaire
            },
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
        onPressed: _showAddSaleForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
