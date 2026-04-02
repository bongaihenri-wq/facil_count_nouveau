import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/core/constants/app_colors.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';
import 'package:facil_count_nouveau/core/widgets/compact_card.dart';
import 'package:facil_count_nouveau/presentation/providers/sale_provider.dart';
import 'package:facil_count_nouveau/core/utils/business_helper.dart';
import 'package:facil_count_nouveau/data/models/sale_model.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedPeriod = 'Mois';
  String _selectedTab = 'Liste';
  String _productFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _exactQuantity;
  double _totalMoisActuel = 0;
  double _totalMoisPrecedent = 0;
  double _difference = 0;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _calculateMonthlyTotals();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('id, name, stock, low_stock_threshold, current_stock:product_current_stock(current_stock)')
          .order('name');
      if (mounted) setState(() => _products = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement produits: ${e.toString()}')),
        );
      }
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
    if (mounted) setState(() {});
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

  List<SaleModel> _filterSales(List<SaleModel> sales) {
    var list = List<SaleModel>.from(sales);
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

    list = list.where((sale) {
      return sale.saleDate.isAfter(periodStart.subtract(const Duration(days: 1))) &&
             sale.saleDate.isBefore(periodEnd);
    }).toList();

    if (_productFilter.isNotEmpty) {
      final q = _productFilter.toLowerCase();
      list = list.where((sale) => 
        sale.productName?.toLowerCase().contains(q) ?? false
      ).toList();
    }

    if (_startDate != null || _endDate != null) {
      list = list.where((sale) {
        if (_startDate != null && sale.saleDate.isBefore(_startDate!)) return false;
        if (_endDate != null && sale.saleDate.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    if (_exactQuantity != null) {
      list = list.where((sale) => sale.quantity == _exactQuantity).toList();
    }

    list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return list;
  }

  Future<void> _showAddSaleForm() async {
    final quantityCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final customerCtrl = TextEditingController();
    Map<String, dynamic>? selectedProduct;
    DateTime saleDate = DateTime.now();
    bool paid = true;

    // ✅ RÉCUPÈRE LE BUSINESS ID DYNAMIQUEMENT
    final businessHelper = ref.read(businessHelperProvider);
    String businessId;
    try {
      businessId = await businessHelper.getBusinessId();
      print('🔍 Business ID récupéré: $businessId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: utilisateur non connecté - $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter une vente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProductDropdown(
                      products: _products,
                      selectedProduct: selectedProduct,
                      onChanged: (value) => setState(() => selectedProduct = value),
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
                      label: 'Date: ${DateFormat('dd/MM/yyyy').format(saleDate)}',
                      onDateSelected: (picked) => setState(() => saleDate = picked),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant total (CFA) *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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

                    final quantity = int.tryParse(quantityCtrl.text.trim()) ?? 0;
                    final totalAmount = double.tryParse(
                          amountCtrl.text.trim().replaceAll(',', '.'),
                        ) ?? 0.0;

                    if (quantity <= 0 || totalAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quantité et montant doivent être valides'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final currentStock = selectedProduct!['current_stock']?['current_stock'] ??
                          selectedProduct!['stock'] ?? 0;

                      if (quantity > currentStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Stock insuffisant (Disponible: $currentStock)'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // ✅ APPEL RPC AVEC BUSINESS ID DYNAMIQUE
                      await _supabase.rpc(
                        'create_sale_with_stock_update',
                        params: {
                          'p_product_id': selectedProduct!['id'],
                          'p_quantity': quantity,
                          'p_total_price': totalAmount,
                          'p_sale_date': saleDate.toIso8601String(),
                          'p_client': customerCtrl.text.trim().isEmpty ? null : customerCtrl.text.trim(),
                          'p_business_id': businessId, // ✅ DYNAMIQUE
                        },
                      );

                      // ✅ Rafraîchit le provider après création
                      ref.invalidate(salesProvider);
                      
                      if (mounted) {
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

  Future<void> _showEditSaleDialog(Map<String, dynamic> sale) async {
    Map<String, dynamic>? selectedProduct;
    final quantityCtrl = TextEditingController(text: sale['quantity'].toString());
    final amountCtrl = TextEditingController(text: sale['amount'].toString());
    final customerCtrl = TextEditingController(text: sale['customer'] ?? '');
    DateTime saleDate = DateTime.tryParse(sale['sale_date'] ?? '') ?? DateTime.now();
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
                    _buildProductDropdown(
                      products: _products,
                      selectedProduct: selectedProduct,
                      onChanged: (value) => setState(() => selectedProduct = value),
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
                      label: 'Date: ${DateFormat('dd/MM/yyyy').format(saleDate)}',
                      onDateSelected: (picked) => setState(() => saleDate = picked),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant total (CFA) *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                      final montantText = amountCtrl.text.trim().replaceAll(',', '.').replaceAll(' ', '');
                      final amount = double.tryParse(montantText) ?? 0.0;

                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Montant invalide')),
                        );
                        return;
                      }

                      await _supabase.from('sales').update({
                        'product_id': selectedProduct!['id'],
                        'quantity': quantity,
                        'amount': amount,
                        'sale_date': saleDate.toIso8601String(),
                        'customer': customerCtrl.text.trim().isEmpty ? null : customerCtrl.text.trim(),
                        'paid': paid,
                        'locked': locked,
                      }).eq('id', sale['id']);

                      ref.invalidate(salesProvider);

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vente modifiée')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
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

      ref.invalidate(salesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final total = salesAsync.when(
      data: (sales) => sales.fold<double>(0.0, (sum, sale) => sum + sale.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
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
              child: Icon(Icons.filter_list, color: AppColors.salesAccent, size: 22),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (sales) {
          final filteredSales = _filterSales(sales);
          
          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('Liste', _selectedTab == 'Liste'),
                    _buildTabButton('Dashboard annuel', _selectedTab == 'Dashboard annuel'),
                  ],
                ),
              ),
              if (_selectedTab == 'Liste') ...[
                _buildTotalCard(total, isSmall),
                _buildPeriodFilterChips(),
                Expanded(
                  child: filteredSales.isEmpty
                      ? const Center(child: Text('Aucune vente trouvée'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          itemCount: filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = filteredSales[index];
                            return CompactSaleCard(
                              productName: sale.productName ?? 'Inconnu',
                              amount: sale.amount,
                              quantity: sale.quantity,
                              date: DateFormat('yyyy-MM-dd').format(sale.saleDate),
                              isLocked: sale.locked,
                              onEdit: () => _showEditSaleDialog(sale.toJson()),
                              onDelete: () => _deleteSale(sale.toJson()),
                            );
                          },
                        ),
                ),
              ] else ...[
                Expanded(child: _buildCompactAnnualDashboard()),
              ],
            ],
          );
        },
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
