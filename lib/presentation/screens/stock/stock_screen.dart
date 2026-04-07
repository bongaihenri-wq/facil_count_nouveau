import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../data/models/product_model.dart';
import '/presentation/providers/stock_provider.dart';
import '/presentation/providers/product_provider.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProducts = ref.watch(filteredStockProvider);
    final stats = ref.watch(stockStatsProvider);
    final searchQuery = ref.watch(productSearchProvider);

    // Déterminer si on est en mode recherche
    final isSearching = searchQuery.isNotEmpty && searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher produit, catégorie, fournisseur...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Mettre à jour le provider de recherche
                  ref.read(productSearchProvider.notifier).state = value;
                },
              )
            : const Text('Gestion des Stocks'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (stats.hasAlerts && !isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                backgroundColor: Colors.red,
                label: Text(
                  '${stats.alertCount}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          // Bouton recherche avec toggle
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (isSearching) {
                // Fermer la recherche et vider le texte
                ref.read(productSearchProvider.notifier).state = '';
              } else {
                // Ouvrir la recherche avec espace pour déclencher le TextField
                ref.read(productSearchProvider.notifier).state = ' ';
              }
            },
          ),
        ],
      ),
      body: filteredProducts.isEmpty && !isSearching
          ? const Center(child: CircularProgressIndicator())
          : filteredProducts.isEmpty && isSearching
          ? const Center(child: Text('Aucun produit trouvé'))
          : Column(
              children: [
                _StatsCard(stats: stats),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) =>
                        _ProductStockCard(product: filteredProducts[index]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInventoryDialog(context, ref),
        backgroundColor: Colors.orange.shade700,
        icon: const Icon(Icons.inventory_2),
        label: const Text('Inventaire'),
      ),
    );
  }

  // INVENTAIRE RESTAURÉ (version précédente)
  void _showInventoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventaire'),
        content: const Text('Que souhaitez-vous faire ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startFullInventory(context, ref);
            },
            child: const Text('Inventaire complet'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showLowStockOnly(context, ref);
            },
            child: const Text('Voir alertes stock'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _startFullInventory(BuildContext context, WidgetRef ref) {
    final products = ref.read(filteredStockProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventaire à faire',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return ListTile(
                    leading: Icon(
                      p.currentStock <= p.lowStockThreshold
                          ? Icons.warning
                          : Icons.check_circle,
                      color: p.currentStock <= p.lowStockThreshold
                          ? Colors.orange
                          : Colors.green,
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      'Stock: ${p.currentStock} / Seuil: ${p.lowStockThreshold}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLowStockOnly(BuildContext context, WidgetRef ref) {
    final alerts = ref.read(stockStatsProvider).lowStockProducts;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Alertes Stock (${alerts.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: alerts.isEmpty
                  ? const Center(child: Text('Aucune alerte ! 🎉'))
                  : ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final p = alerts[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            'Stock: ${p.currentStock} / Min: ${p.lowStockThreshold}',
                          ),
                          trailing: Chip(
                            label: Text('${p.currentStock} restant'),
                            backgroundColor: Colors.red.shade100,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final StockStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.inventory_2,
            value: stats.total,
            label: 'Total',
            color: Colors.orange.shade700,
          ),
          _StatItem(
            icon: Icons.check_circle,
            value: stats.ok,
            label: 'OK',
            color: Colors.green,
          ),
          _StatItem(
            icon: Icons.warning,
            value: stats.low,
            label: 'Bas',
            color: Colors.orange,
          ),
          _StatItem(
            icon: Icons.remove_circle,
            value: stats.out,
            label: 'Rupture',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ProductStockCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductStockCard({required this.product});

  Color _getStockColor() {
    if (product.currentStock <= 0) return const Color(0xFFE53935);
    if (product.currentStock <= product.lowStockThreshold)
      return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockColor = _getStockColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withOpacity(0.2),
          child: Icon(Icons.inventory_2, color: stockColor, size: 20),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${product.category} • Seuil: ${product.lowStockThreshold}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${product.currentStock}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stockColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showAdjustDialog(context, ref, product),
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final controller = TextEditingController(
      text: product.currentStock.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajuster: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actuel : ${product.currentStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true, // Le clavier s'ouvre direct
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité physique',
                border: OutlineInputBorder(),
                suffixText: 'unités',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newStockValue = int.tryParse(controller.text);
              
              if (newStockValue != null) {
                try {
                  // 1. Mise à jour en base de données
                  await ref.read(productActionsProvider).updateStock(product.id, newStockValue);

                  // 2. 🟢 ON FORCE LA MISE À JOUR DE L'INTERFACE ICI
                  ref.invalidate(filteredStockProvider); // Rafraîchit la liste
                  ref.invalidate(stockStatsProvider);    // Rafraîchit les compteurs (Bas, OK, etc.)

                  if (context.mounted) {
                    Navigator.pop(context); // Ferme le dialogue
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stock mis à jour pour ${product.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
}
