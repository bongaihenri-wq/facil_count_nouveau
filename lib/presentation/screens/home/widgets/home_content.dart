import 'package:flutter/material.dart';
import '/presentation/screens/purchases/purchase_screen.dart';
import '/presentation/screens/sales/sale_screen.dart';
import '/presentation/screens/expenses/expense_screen.dart';
import '/presentation/screens/products/product_screen.dart';
import '/presentation/screens/stock/stock_screen.dart';
import '/presentation/screens/invoices/invoices_screen.dart';
import '/presentation/screens/cash/cash_screen.dart';
import '/presentation/screens/dashboard/dashboard_screen.dart';
import 'dashboard_card.dart';
// import 'stock_card.dart'; // ← SUPPRIMÉ - plus besoin
import 'menu_card.dart';
import 'section_title.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const DashboardCard(),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Transactions rapides', icon: Icons.flash_on),
        const SizedBox(height: 12),

        // Section ACHATS / VENTES / DÉPENSES
        MenuCard(
          icon: Icons.shopping_cart,
          title: 'Achats',
          subtitle: 'Enregistrer un achat',
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseScreen()),
          ),
        ),
        MenuCard(
          icon: Icons.point_of_sale,
          title: 'Ventes',
          subtitle: 'Enregistrer une vente',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SaleScreen()),
          ),
        ),
        MenuCard(
          icon: Icons.money_off,
          title: 'Dépenses',
          subtitle: 'Note de frais et dépenses',
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseScreen()),
          ),
        ),

        // Section GESTION - harmonisée, sans StockCard
        MenuCard(
          icon: Icons.business_center,
          title: 'Gestion des stocks',
          subtitle: 'Stocks et inventaires',
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockScreen()),
          ),
        ),
        MenuCard(
          icon: Icons.inventory_2,
          title: 'Produits & Services',
          subtitle: 'Catalogue et prix de vente',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductScreen()),
          ),
        ),
        // const StockCard(), // ← SUPPRIMÉ - causait l'overflow !
        MenuCard(
          icon: Icons.receipt_long,
          title: 'Factures',
          subtitle: 'Gestion des factures',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoicesScreen()),
          ),
        ),
        MenuCard(
          icon: Icons.account_balance_wallet,
          title: 'Caisse',
          subtitle: 'Mouvements de trésorerie',
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CashScreen()),
          ),
        ),

        const SizedBox(height: 20),

        // Tableau de bord en bas
        MenuCard(
          icon: Icons.dashboard,
          title: 'Tableau de bord',
          subtitle: 'Analyses et statistiques',
          color: Colors.purple,
          isOutlined: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          ),
        ),
      ],
    );
  }
}
