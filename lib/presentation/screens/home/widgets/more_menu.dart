import 'package:flutter/material.dart';
import '../../products/product_screen.dart';
import '../../stock/stock_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../cash/cash_screen.dart';
import '/../../screens/invoices_screen.dart';
import '../../expenses/expense_screen.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      children: [
        _GridMenuCard(
          icon: Icons.inventory_2,
          label: 'Produits',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductScreen()),
          ),
        ),
        _GridMenuCard(
          icon: Icons.warehouse,
          label: 'Stocks',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockScreen()),
          ),
        ),
        _GridMenuCard(
          icon: Icons.dashboard,
          label: 'Dashboard',
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          ),
        ),
        _GridMenuCard(
          icon: Icons.account_balance_wallet,
          label: 'Caisse',
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CashScreen()),
          ),
        ),
        _GridMenuCard(
          icon: Icons.receipt_long,
          label: 'Factures',
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoicesScreen()),
          ),
        ),
        _GridMenuCard(
          icon: Icons.money_off,
          label: 'Dépenses',
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseScreen()),
          ),
        ),
      ],
    );
  }
}

class _GridMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
