import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../core/utils/date_filter_helper.dart';
import '/presentation/providers/sale_provider.dart';
import '/presentation/providers/purchase_provider.dart';
import '/presentation/providers/expense_provider.dart';

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
  
  // 1️⃣ On écoute la période sélectionnée spécifiquement pour le Dashboard 🟢
  // Cet objet est STABLE, Riverpod ne bouclera plus dessus.
  final dashboardPeriodRange = ref.watch(selectedDashboardPeriodProvider);

  // 2️⃣ On écoute directement avec l'objet fourni ! 🟢
  final salesAsync = ref.watch(salesProvider(dashboardPeriodRange));
  final purchasesAsync = ref.watch(purchasesProvider(dashboardPeriodRange));
  final expensesAsync = ref.watch(filteredExpensesProvider(dashboardPeriodRange)); 
  
  // ⏳ Gestion des états de chargement
  if (salesAsync is AsyncLoading || purchasesAsync is AsyncLoading || expensesAsync is AsyncLoading) {
    return const AsyncLoading<DashboardGlobalData>();
  }
  
  // ❌ Gestion des états d'erreur si un appel Supabase échoue
  if (salesAsync is AsyncError) {
    return AsyncError<DashboardGlobalData>(salesAsync.error!, salesAsync.stackTrace!);
  }
  if (purchasesAsync is AsyncError) {
    return AsyncError<DashboardGlobalData>(purchasesAsync.error!, purchasesAsync.stackTrace!);
  }
  if (expensesAsync is AsyncError) {
    return AsyncError<DashboardGlobalData>(expensesAsync.error!, expensesAsync.stackTrace!);
  }

  // 📦 Si tout est bon, on extrait les listes (ou une liste vide par défaut)
  final sales = salesAsync.value ?? [];
  final purchases = purchasesAsync.value ?? [];
  final expenses = expensesAsync.value ?? []; 

  // ==========================================
  // 📈 1️⃣ CALCUL DES TOTAUX (Pour les KPIs)
  // ==========================================
  final totalVentes = sales.fold<double>(0, (sum, item) => sum + item.amount);
  final totalAchats = purchases.fold<double>(0, (sum, item) => sum + item.amount);
  final totalDepenses = expenses.fold<double>(0, (sum, item) => sum + item.amount); 

  // ==========================================
  // 📊 2️⃣ ÉVOLUTION MENSUELLE (Pour le graphique)
  // ==========================================
  final List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
  final List<Map<String, dynamic>> monthlyEvolution = [];

  for (int i = 0; i < months.length; i++) {
    final monthIndex = i + 1;
    
    final salesInMonth = sales
        .where((s) => s.saleDate.month == monthIndex)
        .fold<double>(0, (sum, item) => sum + item.amount);
        
    final purchasesInMonth = purchases
        .where((p) => p.purchaseDate.month == monthIndex)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final expensesInMonth = expenses
        .where((e) => e.expensesDate.month == monthIndex)
        .fold<double>(0, (sum, item) => sum + item.amount); 

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
  // 🏆 3️⃣ TOP 5 DES PRODUITS (Pour le Ranking)
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
  // 🚀 4️⃣ RETOUR DES DONNÉES ENVELOPPÉES DANS ASYNCDATA
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
