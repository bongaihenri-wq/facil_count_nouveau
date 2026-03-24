import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchasesListView extends StatelessWidget {
  final List<Map<String, dynamic>> purchases;
  final num total;
  final bool isSmall;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const PurchasesListView({
    super.key,
    required this.purchases,
    required this.total,
    required this.isSmall,
    required this.onEdit,
    required this.onDelete,
  });

  String formatCFA(num amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.abs())} F CFA';
  }

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun achat trouvé.\nAjoutez-en un avec le bouton +',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total achats',
                    style: TextStyle(fontSize: isSmall ? 15 : 17),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCFA(total),
                      style: TextStyle(
                        fontSize: isSmall ? 17 : 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final p = purchases[index];
              final product = p['products'] ?? {};
              final name = product['name'] as String? ?? 'Produit inconnu';
              final qty = p['quantity'] as int? ?? 0;
              final amount = p['amount'] as num? ?? 0.0;
              final date = p['purchase_date'] as String?;
              final locked = p['locked'] as bool? ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          '$qty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date != null
                                  ? date.substring(0, 10)
                                  : 'Date inconnue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCFA(amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              '$qty ×',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: 18,
                                  color: locked
                                      ? Colors.yellow.shade800
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: Colors.blue.shade700,
                                  onPressed: () => onEdit(p),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red.shade700,
                                  onPressed: () => onDelete(p),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
