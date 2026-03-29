import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../../data/models/cash_models.dart';  // ← AJOUTÉ pour TransactionType
import 'widgets/cash_balance_card.dart';
import 'widgets/cash_flow_list.dart';
import 'widgets/debt_summary_card.dart';
import 'widgets/notification_badge.dart';
import 'dialogs/add_transaction_dialog.dart';
import '../notifications_screen.dart';

class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashState = ref.watch(cashProvider);

    // Calcul nombre d'alertes
    final alertCount = cashState.when(
      data: (s) =>
          s.customerDebts.where((d) => (d.paymentDelayDays ?? 0) > 0).length +
          s.supplierDebts.where((d) => (d.paymentDelayDays ?? 0) > 0).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Caisse',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          NotificationBadge(
            count: alertCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cashProvider.notifier).loadData(),
          ),
        ],
      ),
      body: cashState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(cashProvider.notifier).loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Solde principal avec date intégrée
                CashBalanceCard(
                  netFlow: state.summary.netCashFlow,
                  totalIn: state.summary.totalIn,
                  totalOut: state.summary.totalOut,
                  selectedDate: state.selectedDate,
                  onDateTap: () => _showDatePicker(context, ref, state.selectedDate),
                ),
                const SizedBox(height: 20),
                
                // Créances et dettes
                DebtSummaryCard(
                  customerDebts: state.customerDebts,
                  supplierDebts: state.supplierDebts,
                ),
                const SizedBox(height: 20),
                
                // Détail des flux
                _buildCashFlowDetail(state),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(cashProvider.notifier).loadData(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Voir le solde au',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      locale: const Locale('fr'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await ref.read(cashProvider.notifier).setDate(picked);
    }
  }

  Widget _buildCashFlowDetail(CashState state) {
    // Grouper les transactions par type pour l'affichage
    final inflows = state.transactions.where((t) => t.isInflow).toList();
    final outflows = state.transactions.where((t) => t.isOutflow).toList();

    // Calculer les totaux par catégorie pour un affichage plus détaillé
    final Map<TransactionType, double> inflowByType = {};
    final Map<TransactionType, double> outflowByType = {};

    for (final t in inflows) {
      inflowByType[t.type] = (inflowByType[t.type] ?? 0) + t.amount;
    }

    for (final t in outflows) {
      outflowByType[t.type] = (outflowByType[t.type] ?? 0) + t.amount;
    }

    // Créer les items d'affichage
    final inItems = inflowByType.entries.map((e) => CashFlowItem(
      label: e.key.label,
      amount: e.value,
      icon: e.key.icon,
      color: e.key.color,
    )).toList();

    final outItems = outflowByType.entries.map((e) => CashFlowItem(
      label: e.key.label,
      amount: e.value,
      icon: e.key.icon,
      color: e.key.color,
      isNegative: true,
    )).toList();

    // Si pas de transactions, afficher un message
    if (inItems.isEmpty && outItems.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Aucune transaction jusqu\'au ${state.selectedDate.day}/${state.selectedDate.month}/${state.selectedDate.year}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return CashFlowList(
      inItems: inItems,
      outItems: outItems,
    );
  }
}
