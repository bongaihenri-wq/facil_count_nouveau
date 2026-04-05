import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart'; // 1. Séparateur de milliers
import '../../../core/utils/period_picker_bottom_sheet.dart';
import '/presentation/screens/dashboard/providers/dashboard_provider.dart';
import 'widgets/chart_section.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/product_ranking.dart';
import 'widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardGlobalDataProvider);
    final currentPeriod = ref.watch(selectedDashboardPeriodProvider);
    final themeColor = Colors.blue.shade800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fond légèrement grisé pour faire ressortir les cartes blanches
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tableau de Bord',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => ref.invalidate(dashboardGlobalDataProvider),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardGlobalDataProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40), // 6. Padding bas de page
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 7. Filtre avec padding bas
                _buildPeriodSelector(context, ref, currentPeriod, themeColor),
                const SizedBox(height: 24),
                
                // 2. Cartes KPI (Ventes, Achats, Dépenses)
                KPICards(stats: stats),
                const SizedBox(height: 16),
                
                // 2. Carte Marge Centrée
                _MargeCard(stats: stats),
                const SizedBox(height: 24),
                
                // 8. Section Graphique
                ChartSection(monthlyEvolution: stats.monthlyEvolution),
                const SizedBox(height: 24),
                
                ProductRanking(topProducts: stats.topProducts),
                const SizedBox(height: 24),
                
                const QuickActions(),
                const SizedBox(height: 40), // 6. Espace de fin
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  // Helper pour le sélecteur de période (épuré)
  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, currentPeriod, themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // 7. Padding sous le filtre
      child: GestureDetector(
        onTap: () => _showPeriodPicker(context, ref),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: themeColor),
              const SizedBox(width: 12),
              Text(
                currentPeriod.label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: themeColor),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodPickerBottomSheet(
        onPeriodSelected: (newRange) => ref.read(selectedDashboardPeriodProvider.notifier).state = newRange,
      ),
    );
  }
}

class _MargeCard extends StatelessWidget {
  final DashboardGlobalData stats;
  const _MargeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isProfitable = stats.marge >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Marge nette', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          // 1 & 2. Montant formaté et centré
          Text(
            '${Formatters.formatCurrency(stats.marge)} FCFA', // Utilisation de ton formatter
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold,
              color: isProfitable ? Colors.green.shade700 : Colors.red.shade700
            ),
          ),
          const SizedBox(height: 5),
          Icon(
            isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
            size: 28,
          )
        ],
      ),
    );
  }
}