import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../../data/models/product_model.dart'; // AJOUTER CET IMPORT
import 'dialogs/add_product_dialog.dart';
import 'product_list.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final searchQuery = ref.watch(productSearchProvider);
    final isSearching = searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  ref.read(productSearchProvider.notifier).state = value;
                },
              )
            : const Text('Produits & Services'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (isSearching) {
                ref.read(productSearchProvider.notifier).state = '';
              } else {
                ref.read(productSearchProvider.notifier).state = ' ';
              }
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final filtered = _filterProducts(products, searchQuery);
          return ProductList(
            products: filtered,
            onRefresh: () => ref.invalidate(productsProvider),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddProductDialog(context),
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  List<ProductModel> _filterProducts(
    List<ProductModel> products,
    String query,
  ) {
    if (query.isEmpty || query.trim().isEmpty) return products;

    final lowerQuery = query.toLowerCase().trim();
    return products.where((p) {
      // Vérification null-safety pour chaque propriété
      final name = p.name;
      final category = p.category;
      final supplier = p.supplier;
      final currentStock = p.currentStock;

      return name.toLowerCase().contains(lowerQuery) ||
          category.toLowerCase().contains(lowerQuery) ||
          (supplier?.toLowerCase().contains(lowerQuery) ?? false) ||
          currentStock.toString().contains(lowerQuery);
    }).toList();
  }
}
