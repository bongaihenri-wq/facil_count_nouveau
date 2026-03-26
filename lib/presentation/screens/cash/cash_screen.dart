import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/cash_provider.dart';
import 'widgets/cash_balance_card.dart';
import 'widgets/cash_flow_list.dart';
import 'widgets/debt_summary_card.dart';
import 'widgets/notification_badge.dart';
import 'widgets/period_selector.dart';
import 'dialogs/add_transaction_dialog.dart';
import '../notifications_screen.dart';

class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashState = ref.watch(cashProvider);

    // Calculer nombre d'alertes
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
                // Sélecteur période
                PeriodSelector(
                  selectedPeriod: state.selectedPeriod,
                  selectedDate: state.selectedDate,
                  onPeriodChanged: (p) =>
                      ref.read(cashProvider.notifier).setPeriod(p),
                  onDateChanged: (d) =>
                      ref.read(cashProvider.notifier).setDate(d),
                ),
                const SizedBox(height: 20),
                // Solde principal
                CashBalanceCard(
                  netFlow: state.summary.netCashFlow,
                  totalIn: state.summary.totalIn,
                  totalOut: state.summary.totalOut,
                ),
                const SizedBox(height: 20),
                // Créances et dettes
                DebtSummaryCard(
                  customerDebts: state.customerDebts,
                  supplierDebts: state.supplierDebts,
                ),
                const SizedBox(height: 20),
                // Détail entrées/sorties
                CashFlowList(
                  inItems: [
                    CashFlowItem(
                      label: 'Ventes au comptant',
                      amount: state.summary.cashSales,
                      icon: Icons.point_of_sale,
                      color: Colors.green,
                    ),
                    CashFlowItem(
                      label: 'Créances encaissées',
                      amount: 0,
                      icon: Icons.money,
                      color: Colors.teal,
                    ),
                  ],
                  outItems: [
                    CashFlowItem(
                      label: 'Achats au comptant',
                      amount: state.summary.cashPurchases,
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      isNegative: true,
                    ),
                    CashFlowItem(
                      label: 'Dépenses diverses',
                      amount: state.summary.expenses,
                      icon: Icons.receipt_long,
                      color: Colors.red,
                      isNegative: true,
                    ),
                    CashFlowItem(
                      label: 'Versements banque',
                      amount: state.summary.bankDeposits,
                      icon: Icons.account_balance,
                      color: Colors.blue,
                      isNegative: true,
                    ),
                    CashFlowItem(
                      label: 'Retraits / Transferts',
                      amount:
                          state.summary.withdrawals +
                          state.summary.ownerTransfers,
                      icon: Icons.payments,
                      color: Colors.purple,
                      isNegative: true,
                    ),
                  ],
                ),
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
}
