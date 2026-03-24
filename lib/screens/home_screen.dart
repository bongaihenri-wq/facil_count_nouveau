import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
// import 'purchases_screen.dart';
// import 'sales_screen_old.dart';
// import 'expenses_screen_old.dart';
import 'invoices_screen.dart';
import 'products_screen.dart';
import 'cash_screen.dart';
import 'package:facil_count_nouveau/presentation/screens/sales/sale_screen.dart';
import 'package:facil_count_nouveau/presentation/screens/expenses/expense_screen.dart';
import 'package:facil_count_nouveau/presentation/screens/purchases/purchase_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facil Count'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),

      // Corps principal
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Achats
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.blue),
              title: const Text('Achats'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseScreen()),
              ),
            ),
          ),

          // Ventes
          Card(
            child: ListTile(
              leading: const Icon(Icons.point_of_sale, color: Colors.green),
              title: const Text('Ventes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaleScreen()),
              ),
            ),
          ),

          // Dépenses
          Card(
            child: ListTile(
              leading: const Icon(Icons.money_off, color: Colors.red),
              title: const Text('Dépenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseScreen()),
              ),
            ),
          ),

          // Factures
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: const Text('Factures'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InvoicesScreen()),
              ),
            ),
          ),

          // Dashboard
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.purple),
              title: const Text('Dashboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              ),
            ),
          ),

          // Produits / Services
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.teal),
              title: const Text('Produits / Services'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              ),
            ),
          ),

          // Nouvelle page : Caisse
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.indigo,
              ),
              title: const Text('Caisse'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CashScreen()),
              ),
            ),
          ),
        ],
      ),

      // Bouton flottant + (pour ajouter une transaction caisse rapidement, par exemple)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Optionnel : ouvrir directement un formulaire d'ajout de transaction caisse
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AddCashTransactionScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajout transaction caisse (à implémenter)'),
            ),
          );
        },
      ),

      // BottomNavigationBar (si tu en veux une, sinon tu peux la supprimer)
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Achats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Plus'),
        ],
        currentIndex: 0, // À dynamiser si tu veux
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Ajoute la navigation ici si besoin
        },
      ),
    );
  }
}
