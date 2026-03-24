import 'package:flutter/material.dart';
import '../../../../data/models/sale_model.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

class SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SaleCard({
    super.key,
    required this.sale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green.shade100,
              child: const Icon(
                Icons.point_of_sale,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: _buildInfo()),
            // Actions
            SizedBox(width: 140, child: _buildActions()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom produit
        Text(
          sale.productName ?? 'Produit inconnu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        // Quantité × prix (NOUVEAU)
        Text(
          '${sale.quantity}x @ ${sale.unitPrice.toStringAsFixed(0)} CFA',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        // Date
        Text(
          sale.formattedDate,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Montant
        Text(
          Formatters.formatCurrency(
            sale.amount,
          ), // Au lieu de sale.formattedAmount
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 4),
        // Icônes
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 18,
              color: sale.locked ? Colors.orange : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
              onPressed: onEdit,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.delete, size: 20, color: Colors.red.shade700),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}
