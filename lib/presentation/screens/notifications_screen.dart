import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cash_models.dart';
import '../../../presentation/providers/cash_provider.dart';
import '../../../core/services/debt_notification_service.dart';
import '../../../core/utils/formatters.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashState = ref.watch(cashProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes Dettes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(context),
            tooltip: 'Tout marquer comme lu',
          ),
        ],
      ),
      body: cashState.when(
        data: (state) {
          final overdueCustomers = state.customerDebts
              .where((d) => (d.paymentDelayDays ?? 0) > 0)
              .toList();
          final overdueSuppliers = state.supplierDebts
              .where((d) => (d.paymentDelayDays ?? 0) > 0)
              .toList();

          if (overdueCustomers.isEmpty && overdueSuppliers.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdueCustomers.isNotEmpty) ...[
                _buildSectionTitle('Créances en retard', Colors.orange),
                const SizedBox(height: 12),
                ...overdueCustomers.map((d) => _buildDebtCard(d, context, ref)),
                const SizedBox(height: 24),
              ],
              if (overdueSuppliers.isNotEmpty) ...[
                _buildSectionTitle('Dettes à payer urgentes', Colors.red),
                const SizedBox(height: 12),
                ...overdueSuppliers.map((d) => _buildDebtCard(d, context, ref)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes vos dettes sont à jour !',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, MaterialColor color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtCard(DebtInfo debt, BuildContext context, WidgetRef ref) {
    final days = debt.paymentDelayDays ?? 0;
    final isSevere = days > 30;
    final color = debt.type == 'customer' ? Colors.orange : Colors.red;

    return Dismissible(
      key: Key('${debt.name}_${debt.date}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (_) => _markAsResolved(debt, ref),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSevere ? Colors.red.shade200 : Colors.transparent,
            width: isSevere ? 2 : 0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: color.shade100,
            child: Icon(
              debt.type == 'customer' ? Icons.person : Icons.business,
              color: color.shade700,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  debt.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSevere ? Colors.red.shade100 : color.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSevere ? '⚠️ $days j' : '+$days j',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSevere ? Colors.red.shade800 : color.shade800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Montant: ${Formatters.formatCurrency(debt.amount)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (debt.phone != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _callNumber(debt.phone!),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        debt.phone!,
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'call':
                  if (debt.phone != null) _callNumber(debt.phone!);
                  break;
                case 'remind':
                  _scheduleReminder(debt);
                  break;
                case 'paid':
                  _markAsResolved(debt, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (debt.phone != null)
                const PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 20),
                      SizedBox(width: 8),
                      Text('Appeler'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remind',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Rappel plus tard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'paid',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Marquer payé', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callNumber(String phone) {
    // Utiliser url_launcher
    // launchUrl(Uri.parse('tel:$phone'));
  }

  void _scheduleReminder(DebtInfo debt) {
    // Ouvrir date picker pour planifier rappel
  }

  void _markAsResolved(DebtInfo debt, WidgetRef ref) {
    // Logique pour marquer comme payé
    // Mettre à jour dans Supabase
  }

  // ✅ CORRIGÉ - Utilise cancelAll() au lieu de cancelAllNotifications()
  void _markAllAsRead(BuildContext context) {
    DebtNotificationService().cancelAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été effacées'),
      ),
    );
  }
}
