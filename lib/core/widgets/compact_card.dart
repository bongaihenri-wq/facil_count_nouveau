import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/constants/app_colors.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';

class CompactSaleCard extends StatelessWidget {
  final String productName;
  final double amount;
  final int quantity;
  final String date;
  final bool isLocked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactSaleCard({
    super.key,
    required this.productName,
    required this.amount,
    required this.quantity,
    required this.date,
    required this.isLocked,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icône ou indicateur de verrouillage
            Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked ? AppColors.error : AppColors.neutral,
              size: 20,
            ),
            const SizedBox(width: 12),
            // Détails de la vente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantité: $quantity | Date: $date',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCFA(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.salesPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Boutons d'action
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.salesAccent),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
