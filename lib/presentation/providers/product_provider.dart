import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import 'expense_provider.dart'; // Pour supabaseClientProvider

final productRepositoryProvider = Provider(
  (ref) => ProductRepository(ref.watch(supabaseClientProvider)),
);

// 🔥 PROVIDER GLOBAL - Utilisable par tous les écrans
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProducts();
});
