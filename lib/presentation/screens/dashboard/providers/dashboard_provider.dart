import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../core/utils/date_filter_helper.dart';
import '/presentation/providers/sale_provider.dart';
import '/presentation/providers/purchase_provider.dart';
import '/presentation/providers/expense_provider.dart';
import '/data/models/expense_model.dart';

final currentScreenProvider = StateProvider<String>((ref) => 'dashboard');

/// 🎯 1. Le provider d'état pour la période du Dashboard Global
final selectedDashboardPeriodProvider = StateProvider<DateFilterRange>((ref) {
  return DateFilterHelper.defaultRange();
});

/// 📦 2. Modèle de données complet pour porter les états du Dashboard
class DashboardGlobalData {
  final double totalVentes;
  final double totalAchats;
  final double totalDepenses;
  final double marge;
  final List<Map<String, dynamic>> monthlyEvolution;
  final List<Map<String, dynamic>> topProducts;

  DashboardGlobalData({
    required this.totalVentes,
    required this.totalAchats,
    required this.totalDepenses,
    required this.marge,
    required this.monthlyEvolution,
    required this.topProducts,
  });
}

/// 🧮 3. Le Provider dérivé qui calcule tout à la volée !
final dashboardGlobalDataProvider = Provider<AsyncValue<DashboardGlobalData>>((ref) {
  
  // 1️⃣ On écoute la période sélectionnée
  final dashboardPeriodRange = ref.watch(selectedDashboardPeriodProvider);

  // 2️⃣ Récupération des données
  final salesAsync = ref.watch(salesProvider(dashboardPeriodRange));
  final purchasesAsync = ref.watch(purchasesProvider(dashboardPeriodRange));
  
  // 🟢 Correction : expenses est DIRECTEMENT une List<ExpenseModel>
  // car filteredExpensesProvider est maintenant un Provider simple.
 final List<ExpenseModel> expenses = ref.watch(filteredExpensesProvider);
  
  // ⏳ Gestion des états de chargement (uniquement pour Ventes et Achats)
  if (salesAsync is AsyncLoading || purchasesAsync is AsyncLoading) {
    return const AsyncLoading<DashboardGlobalData>();
  }
  
  // ❌ Gestion des états d'erreur (uniquement pour Ventes et Achats)
  if (salesAsync is AsyncError) {
    return AsyncError<DashboardGlobalData>(salesAsync.error!, salesAsync.stackTrace!);
  }
  if (purchasesAsync is AsyncError) {
    return AsyncError<DashboardGlobalData>(purchasesAsync.error!, purchasesAsync.stackTrace!);
  }

  // 📦 Extraction des listes pour Ventes et Achats
  final sales = salesAsync.value ?? [];
  final purchases = purchasesAsync.value ?? [];
  // Note : 'expenses' est déjà extrait plus haut car c'est une liste directe.

  // ==========================================
  // 📈 1️⃣ CALCUL DES TOTAUX
  // ==========================================
  final totalVentes = sales.fold<double>(0, (sum, item) => sum + item.amount);
  final totalAchats = purchases.fold<double>(0, (sum, item) => sum + item.amount);
  final totalDepenses = expenses.fold<double>(0, (sum, item) => sum + item.amount); 

  // ==========================================
  // 📊 2️⃣ ÉVOLUTION MENSUELLE
  // ==========================================
  final List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
  final List<Map<String, dynamic>> monthlyEvolution = [];

  for (int i = 0; i < months.length; i++) {
    final int monthIndex = i + 1;
    
    // --- VENTES ---
    final salesInMonth = sales.where((s) {
      // Sécurité renforcée : on vérifie que s et saleDate ne sont pas nuls
      return s.saleDate.month == monthIndex;
    }).fold<double>(0, (sum, item) => sum + (item.amount));
        
    // --- ACHATS ---
    final purchasesInMonth = purchases.where((p) {
      return p.purchaseDate.month == monthIndex;
    }).fold<double>(0, (sum, item) => sum + (item.amount));

    // --- DEPENSES ---
    final expensesInMonth = expenses.where((e) {
      // On teste les deux noms de champs possibles pour la date
      final dateValue = e.date ?? e.expensesDate;
      if (dateValue == null) return false;
      return dateValue.month == monthIndex;
    }).fold<double>(0, (sum, item) => sum + (item.amount)); 

    // Ajout à la liste si un montant existe
    if (salesInMonth > 0 || purchasesInMonth > 0 || expensesInMonth > 0) {
      monthlyEvolution.add({
        'month': months[i],
        'ventes': salesInMonth,
        'achats': purchasesInMonth,
        'depenses': expensesInMonth, 
      });
    }
  }

  // ==========================================
  // 🏆 3️⃣ TOP 5 DES PRODUITS
  // ==========================================
  final Map<String, double> productSalesQuantities = {};
  
  for (var sale in sales) {
    final prodName = sale.productName ?? 'Inconnu';
    productSalesQuantities[prodName] = (productSalesQuantities[prodName] ?? 0) + sale.quantity;
  }

  final topProducts = productSalesQuantities.entries
      .map((e) => {'name': e.key, 'qty': e.value})
      .toList()
    ..sort((a, b) => (b['qty'] as double).compareTo(a['qty'] as double));

  final top5 = topProducts.take(5).toList();

  // ==========================================
  // 🚀 4️⃣ RETOUR DES DONNÉES
  // ==========================================
  return AsyncData(DashboardGlobalData(
    totalVentes: totalVentes,
    totalAchats: totalAchats,
    totalDepenses: totalDepenses,
    marge: totalVentes - (totalAchats + totalDepenses), 
    monthlyEvolution: monthlyEvolution,
    topProducts: top5,
  ));
});
