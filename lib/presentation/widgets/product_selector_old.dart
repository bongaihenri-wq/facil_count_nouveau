// lib/presentation/screens/sales/widgets/product_selector.dart

import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';

class ProductSelector extends StatelessWidget {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel?> onChanged;
  final bool allowOutOfStock; // Pour réutiliser dans achats

  const ProductSelector({
    super.key,
    required this.products,
    this.selectedProduct,
    required this.onChanged,
    this.allowOutOfStock = false, // Par défaut: interdit pour ventes
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Trier: produits avec stock d'abord, puis par nom
    final validProducts = products
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList()
      ..sort((a, b) {
        if (a.isOutOfStock && !b.isOutOfStock) return 1;
        if (!a.isOutOfStock && b.isOutOfStock) return -1;
        return a.name.compareTo(b.name);
      });

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
        final isOutOfStock = product.isOutOfStock;
        final isLowStock = product.isLowStock;
        
        // 🔥 Couleur du badge stock
        final stockColor = isOutOfStock
            ? Colors.red
            : (isLowStock ? Colors.orange : Colors.green);

        return DropdownMenuItem<ProductModel?>(
          value: product,
          enabled: allowOutOfStock || !isOutOfStock, // Désactivé si rupture pour ventes
          child: Opacity(
            opacity: isOutOfStock ? 0.5 : 1.0, // 🔥 Grisé si rupture
            child: Row(
              children: [
                // 🔥 Nom du produit avec stock entre parenthèses
                Expanded(
                  child: Text(
                    '${product.name} (${product.currentStock} dispo)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOutOfStock ? Colors.grey : Colors.black87,
                      fontWeight: isOutOfStock ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 🔥 Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stockColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isOutOfStock 
                        ? 'RUPTURE' 
                        : (isLowStock ? 'STOCK BAS' : 'OK'),
                    style: TextStyle(
                      color: stockColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (ProductModel? value) {
        if (value != null && value.isOutOfStock && !allowOutOfStock) {
          // 🔥 Avertissement si tentative de sélection en rupture
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${value.name} est en rupture de stock'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        onChanged(value);
      },
      decoration: InputDecoration(
        labelText: 'Produit *',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        // 🔥 Icône d'info si produit sélectionné
        suffixIcon: selectedProduct != null
            ? Tooltip(
                message: 'Stock: ${selectedProduct!.currentStock} unités',
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: selectedProduct!.stockColor,
                ),
              )
            : null,
      ),
    );
  }
}
