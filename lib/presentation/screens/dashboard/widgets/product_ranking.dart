import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class ProductRanking extends ConsumerWidget {
  const ProductRanking({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return state.when(
      data: (stats) => Column(
        children: [
          _RankingCard(
            title: '🔥 Top 5 produits',
            subtitle: 'Les plus vendus',
            products: stats.bestProducts,
            color: Colors.green.shade700,
            icon: Icons.emoji_events,
          ),
          const SizedBox(height: 16),
          _RankingCard(
            title: '⚠️ À surveiller',
            subtitle: 'Les moins vendus',
            products: stats.worstProducts,
            color: Colors.red.shade700,
            icon: Icons.warning_amber,
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ProductSale> products;
  final Color color;
  final IconData icon;

  const _RankingCard({
    required this.title,
    required this.subtitle,
    required this.products,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune donnée disponible'),
                ),
              )
            else
              ...products.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                return _ProductRow(rank: index + 1, product: p, color: color);
              }),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final ProductSale product;
  final Color color;

  const _ProductRow({
    required this.rank,
    required this.product,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Badge de rang
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom et quantité
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Formatters.formatNumber(product.quantity.toInt())} vendus',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Montant/CA uniquement
          Text(
            Formatters.formatCurrency(product.revenue),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne la couleur du badge selon le rang
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Or
      case 2:
        return Colors.grey.shade500; // Argent
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blueGrey.shade400; // Autres
    }
  }
}
