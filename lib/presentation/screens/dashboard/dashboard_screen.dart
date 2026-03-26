import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/period_selector.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/chart_section.dart';
import 'widgets/product_ranking.dart';
import 'widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // ou ta couleur
        iconTheme: IconThemeData(color: Colors.black87), // icônes noires
        title: Text(
          'Tableau de bord',
          style: TextStyle(
            color: Colors.black87, // ← FORCER la couleur du texte
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        // Alternative: utiliser foregroundColor pour tout
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PeriodSelector(),
              const SizedBox(height: 20),
              const KPICards(),
              const SizedBox(height: 24),
              const ChartSection(),
              const SizedBox(height: 24),
              const ProductRanking(),
              const SizedBox(height: 24),
              const QuickActions(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
