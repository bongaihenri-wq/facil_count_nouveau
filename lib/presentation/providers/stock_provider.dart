import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../data/models/product_model.dart';
import '/../presentation/providers/product_provider.dart';

// Provider pour les stats stock
final stockStatsProvider = Provider<StockStats>((ref) {
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.when(
    data: (products) {
      final low = products
          .where(
            (p) => p.currentStock <= p.lowStockThreshold && p.currentStock > 0,
          )
          .length;
      final out = products.where((p) => p.currentStock <= 0).length;
      return StockStats(
        total: products.length,
        ok: products.where((p) => p.currentStock > p.lowStockThreshold).length,
        low: low,
        out: out,
        hasAlerts: low > 0 || out > 0,
        alertCount: low + out,
        lowStockProducts: products
            .where((p) => p.currentStock <= p.lowStockThreshold)
            .toList(),
      );
    },
    loading: () => StockStats.empty(),
    error: (_, __) => StockStats.empty(),
  );
});

// CORRECTION: La recherche fonctionne maintenant
final filteredStockProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchProvider);

  // Trim pour éviter les espaces
  final lowerQuery = searchQuery.toLowerCase().trim();

  return productsAsync.when(
    data: (products) {
      // Si vide ou juste un espace, retourner tout
      if (lowerQuery.isEmpty) return products;

      // Filtrer selon la recherche
      return products.where((p) {
        final nameMatch = p.name.toLowerCase().contains(lowerQuery);
        final categoryMatch = p.category.toLowerCase().contains(lowerQuery);
        final supplierMatch =
            p.supplier?.toLowerCase().contains(lowerQuery) ?? false;
        final stockMatch = p.currentStock.toString().contains(lowerQuery);

        return nameMatch || categoryMatch || supplierMatch || stockMatch;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class StockStats {
  final int total;
  final int ok;
  final int low;
  final int out;
  final bool hasAlerts;
  final int alertCount;
  final List<ProductModel> lowStockProducts;

  StockStats({
    required this.total,
    required this.ok,
    required this.low,
    required this.out,
    required this.hasAlerts,
    required this.alertCount,
    required this.lowStockProducts,
  });

  factory StockStats.empty() {
    return StockStats(
      total: 0,
      ok: 0,
      low: 0,
      out: 0,
      hasAlerts: false,
      alertCount: 0,
      lowStockProducts: [],
    );
  }
}
