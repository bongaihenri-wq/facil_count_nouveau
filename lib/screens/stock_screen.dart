import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  String _selectedFilter = 'Tous'; // Tous / Bas stock

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final productsRes = await supabase
          .from('products')
          .select('id, name, stock, low_stock_threshold')
          .order('name');

      final List<Map<String, dynamic>> productsWithStock = [];

      for (var product in productsRes) {
        final productId = product['id'];
        final name = product['name'] as String? ?? 'Produit inconnu';
        final initialStock = (product['stock'] as int?) ?? 0;
        final threshold = (product['low_stock_threshold'] as int?) ?? 10;

        final purchasesRes = await supabase
            .from('purchases')
            .select('quantity')
            .eq('product_id', productId);
        final purchasesQty = (purchasesRes as List).fold<int>(
          0,
          (sum, item) => sum + (item['quantity'] as int? ?? 0),
        );

        final salesRes = await supabase
            .from('sales')
            .select('quantity')
            .eq('product_id', productId);
        final salesQty = (salesRes as List).fold<int>(
          0,
          (sum, item) => sum + (item['quantity'] as int? ?? 0),
        );

        final currentStock = initialStock + purchasesQty - salesQty;

        productsWithStock.add({
          'id': productId,
          'name': name,
          'initial_stock': initialStock,
          'purchases_qty': purchasesQty,
          'sales_qty': salesQty,
          'current_stock': currentStock,
          'low_stock_threshold': threshold,
        });
      }

      if (!mounted) return;

      setState(() {
        _products = productsWithStock;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement stock : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    var list = List<Map<String, dynamic>>.from(_products);

    if (_selectedFilter == 'Bas stock') {
      list = list.where((p) {
        final current = p['current_stock'] as int;
        final threshold = p['low_stock_threshold'] as int;
        return current <= threshold;
      }).toList();
    }

    // Tri : produits en bas stock en haut, puis par nom
    list.sort((a, b) {
      final stockA = a['current_stock'] as int;
      final stockB = b['current_stock'] as int;
      final thresholdA = a['low_stock_threshold'] as int;
      final thresholdB = b['low_stock_threshold'] as int;

      if (stockA <= thresholdA && stockB > thresholdB) return -1;
      if (stockB <= thresholdB && stockA > thresholdA) return 1;

      return stockA.compareTo(stockB);
    });

    return list;
  }

  Color getStockColor(int stock, int threshold) {
    if (stock <= 0) return Colors.red[800]!;
    if (stock <= threshold) return Colors.orange[800]!;
    return Colors.green[800]!;
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = filteredProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock & Inventaire')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres améliorés
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Tous les produits'),
                        selected: _selectedFilter == 'Tous',
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _selectedFilter = 'Tous');
                        },
                        selectedColor: Colors.blue[700],
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: _selectedFilter == 'Tous'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: _selectedFilter == 'Tous'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        avatar: _selectedFilter == 'Tous'
                            ? const Icon(
                                Icons.list,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      FilterChip(
                        label: const Text('Bas stock'),
                        selected: _selectedFilter == 'Bas stock',
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _selectedFilter = 'Bas stock');
                        },
                        selectedColor: Colors.orange[700],
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: _selectedFilter == 'Bas stock'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: _selectedFilter == 'Bas stock'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        avatar: _selectedFilter == 'Bas stock'
                            ? const Icon(
                                Icons.warning_amber,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: displayedList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedFilter == 'Bas stock'
                                    ? Icons.sentiment_satisfied
                                    : Icons.inventory,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFilter == 'Bas stock'
                                    ? 'Aucun produit en bas stock'
                                    : 'Aucun produit enregistré',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilter == 'Bas stock'
                                    ? 'Tous les produits ont un stock suffisant !'
                                    : 'Ajoutez des produits pour commencer',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: displayedList.length,
                          itemBuilder: (context, index) {
                            final p = displayedList[index];
                            final name =
                                p['name'] as String? ?? 'Produit inconnu';
                            final initial = p['initial_stock'] as int? ?? 0;
                            final purchases = p['purchases_qty'] as int? ?? 0;
                            final sales = p['sales_qty'] as int? ?? 0;
                            final current = p['current_stock'] as int? ?? 0;
                            final threshold =
                                p['low_stock_threshold'] as int? ?? 10;

                            final color = getStockColor(current, threshold);
                            final isLow = current <= threshold;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: color.withOpacity(0.15),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: color,
                                        size: 28,
                                      ),
                                    ),
                                    if (isLow)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[600],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Text(
                                            '!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 16,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Achats : $purchases',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.remove_circle_outline,
                                          size: 16,
                                          color: Colors.red[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ventes : $sales',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock restant : $current',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    if (isLow)
                                      Text(
                                        current <= 0
                                            ? 'Rupture de stock !'
                                            : 'Stock bas (seuil : $threshold)',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Édition stock (à venir)',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal[700],
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajout produit (à venir)')),
          );
        },
      ),
    );
  }
}
