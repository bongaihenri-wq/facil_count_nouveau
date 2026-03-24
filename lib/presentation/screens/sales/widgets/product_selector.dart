import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';

class ProductSelector extends StatelessWidget {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel?> onChanged;

  const ProductSelector({
    super.key,
    required this.products,
    this.selectedProduct,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validProducts = products
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();

    if (validProducts.isEmpty) {
      return const Text(
        'Aucun produit disponible',
        style: TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<ProductModel?>(
      value: selectedProduct,
      isExpanded: true,
      hint: const Text('Sélectionnez un produit'),
      items: validProducts.map((product) {
        final color = product.isOutOfStock
            ? Colors.red
            : (product.isLowStock ? Colors.orange : Colors.green);

        return DropdownMenuItem<ProductModel?>(
          value: product,
          enabled: true, // 🔥 TOUJOURS ACTIVÉ (même si stock 0)
          child: Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // 🔥 Grisé si rupture mais cliquable
                    color: product.isOutOfStock ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${product.currentStock}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (ProductModel? value) {
        print('Sélection: ${value?.name}'); // Debug
        if (value != null && value.isOutOfStock) {
          // 🔥 Afficher avertissement si stock 0
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${value.name} est en rupture de stock !'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        onChanged(value);
      },
      decoration: const InputDecoration(
        labelText: 'Produit *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}
