import 'package:flutter/material.dart';
import '../../purchases/purchase_screen.dart';
import '../../sales/sale_screen.dart';
import '../../expenses/expense_screen.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color.fromARGB(185, 203, 231, 207),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nouvelle Transaction',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _TransactionOption(
            icon: Icons.shopping_cart,
            color: Colors.blue.shade700,
            label: 'Achat',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TransactionOption(
            icon: Icons.point_of_sale,
            color: Colors.green.shade700,
            label: 'Vente',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaleScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TransactionOption(
            icon: Icons.receipt_long,
            color: Colors.orange.shade700,
            label: 'Dépense',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TransactionOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _TransactionOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
