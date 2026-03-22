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
    return DropdownButtonFormField<ProductModel>(
      value: selectedProduct,
      isExpanded: true, // ← IMPORTANT pour éviter overflow
      items: products.map((product) {
        final color = product.isOutOfStock
            ? Colors.red
            : (product.isLowStock ? Colors.orange : Colors.green);

        return DropdownMenuItem<ProductModel>(
          value: product,
          enabled: !product.isOutOfStock,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Produit *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      hint: const Text('Sélectionnez un produit'),
    );
  }
}
