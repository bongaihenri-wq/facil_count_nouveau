import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import 'dialogs/edit_product_dialog.dart';
import 'product_card.dart';

class ProductList extends ConsumerWidget {
  final List<ProductModel> products;
  final VoidCallback? onRefresh;

  const ProductList({super.key, required this.products, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit enregistré',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier produit ou service',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsProvider);
        onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onEdit: () => _showEditDialog(context, ref, products[index]),
          onDelete: () => _confirmDelete(context, ref, products[index]),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    showEditProductDialog(context, product);
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(productNotifierProvider.notifier)
                  .deleteProduct(product.id);
              ref.invalidate(productsProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
