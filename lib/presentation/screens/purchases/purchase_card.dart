import 'package:facil_count_nouveau/data/models/purchase_model.dart';
import 'package:flutter/material.dart';
import '../../../data/models/purchase_model.dart';

class PurchaseCard extends StatelessWidget {
  final PurchaseModel purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PurchaseCard({
    super.key,
    required this.purchase,
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
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo()),
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
        Text(
          purchase.productName ?? 'Produit inconnu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${purchase.quantity}x @ ${purchase.unitPrice.toStringAsFixed(0)} CFA',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (purchase.supplier != null)
          Text(
            'Fournisseur: ${purchase.supplier}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 2),
        Text(
          purchase.formattedDate,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          purchase.formattedAmount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 18,
              color: purchase.locked ? Colors.orange : Colors.grey.shade400,
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
