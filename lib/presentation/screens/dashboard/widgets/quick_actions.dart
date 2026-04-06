import 'package:flutter/material.dart';
// Si ton écran de caisse a aussi migré, adapte ce chemin comme pour le stock !
import '/presentation/screens/cash/cash_screen.dart'; 
import '/presentation/screens/stock/stock_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Accès rapide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Stock',
                icon: Icons.inventory_2,
                color: Colors.purple.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Caisse',
                icon: Icons.point_of_sale,
                color: Colors.indigo.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CashScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
