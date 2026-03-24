// stock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('products')
          .select('id, name, initial_stock, current_stock')
          .order('name');
      setState(() => _products = data);
    } catch (e) {
      _showError('Chargement produits', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String context, dynamic error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text('$context: ${_getErrorMessage(error)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) return error.message;
    if (error is Exception) return error.toString();
    return 'Erreur inconnue';
  }

  Future<void> _updateStock(String productId, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'current_stock': newStock})
          .eq('id', productId);
      await _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Mise à jour stock', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des stocks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher un produit',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final initialStock = product['initial_stock'] ?? 0;
                      final currentStock = product['current_stock'] ?? 0;
                      final difference = currentStock - initialStock;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product['name'] ?? 'Inconnu',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<int>(
                                    onSelected: (value) async {
                                      await _updateStock(product['id'], value);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 0,
                                        child: Text('Réinitialiser le stock'),
                                      ),
                                      PopupMenuItem(
                                        value: initialStock,
                                        child: const Text(
                                          'Réinitialiser à stock initial',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Stock initial:'),
                                  Text(
                                    '$initialStock',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Stock actuel:'),
                                  Text(
                                    '$currentStock',
                                    style: TextStyle(
                                      color: currentStock > 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Différence:'),
                                  Text(
                                    difference >= 0
                                        ? '+$difference'
                                        : '$difference',
                                    style: TextStyle(
                                      color: difference >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showAdjustStockDialog(product);
                                      },
                                      child: const Text('Ajuster le stock'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showAdjustStockDialog(Map<String, dynamic> product) {
    final currentStock = product['current_stock'] ?? 0;
    final stockCtrl = TextEditingController(text: currentStock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajuster le stock de ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nouveau stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              Text(
                'Stock actuel: $currentStock',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newStock = int.tryParse(stockCtrl.text) ?? 0;
                await _updateStock(product['id'], newStock);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
