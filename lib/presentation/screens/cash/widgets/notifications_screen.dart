import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../../data/models/cash_models.dart';
import '/../../../presentation/providers/cash_provider.dart';
import '/../../../core/services/debt_notification_service.dart';
import '/../../../core/utils/formatters.dart';

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
            padding: const EdgeInsets.all(12), // ← Réduit de 16 à 12
            children: [
              if (overdueCustomers.isNotEmpty) ...[
                _buildSectionTitle('Créances en retard', Colors.orange),
                const SizedBox(height: 8), // ← Réduit de 12 à 8
                ...overdueCustomers.map((d) => _buildDebtCard(d, context, ref)),
                const SizedBox(height: 16), // ← Réduit de 24 à 16
              ],
              if (overdueSuppliers.isNotEmpty) ...[
                _buildSectionTitle('Dettes à payer urgentes', Colors.red),
                const SizedBox(height: 8), // ← Réduit de 12 à 8
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
            size: 64, // ← Réduit de 80 à 64
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 12), // ← Réduit de 16 à 12
          Text(
            'Aucune alerte',
            style: TextStyle(
              fontSize: 18, // ← Réduit de 20 à 18
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4), // ← Réduit de 8 à 4
          Text(
            'Toutes vos dettes sont à jour !',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13, // ← Ajouté taille réduite
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, MaterialColor color) {
    return Row(
      children: [
        Container(
          width: 3, // ← Réduit de 4 à 3
          height: 20, // ← Réduit de 24 à 20
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8), // ← Réduit de 12 à 8
        Text(
          title,
          style: TextStyle(
            fontSize: 16, // ← Réduit de 18 à 16
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
        padding: const EdgeInsets.only(right: 16), // ← Réduit de 20 à 16
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20), // ← Ajouté size 20
      ),
      onDismissed: (_) => _markAsResolved(debt, ref),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 8), // ← Ajouté margin réduit
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSevere ? Colors.red.shade200 : Colors.transparent,
            width: isSevere ? 2 : 0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← Réduit de all(16)
          minLeadingWidth: 40, // ← Ajouté pour contrôler largeur leading
          leading: CircleAvatar(
            radius: 18, // ← Ajouté rayon réduit (défaut 20)
            backgroundColor: color.shade100,
            child: Icon(
              debt.type == 'customer' ? Icons.person : Icons.business,
              color: color.shade700,
              size: 18, // ← Ajouté taille icône réduite
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  debt.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // ← Ajouté taille réduite
                  ),
                  maxLines: 1, // ← Ajouté pour éviter débordement
                  overflow: TextOverflow.ellipsis, // ← Ajouté ellipsis
                ),
              ),
              const SizedBox(width: 8), // ← Ajouté espace minimum
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // ← Réduit de 8/4 à 6/3
                decoration: BoxDecoration(
                  color: isSevere ? Colors.red.shade100 : color.shade100,
                  borderRadius: BorderRadius.circular(16), // ← Réduit de 20 à 16
                ),
                child: Text(
                  isSevere ? '⚠️ $days j' : '+$days j',
                  style: TextStyle(
                    fontSize: 11, // ← Réduit de 12 à 11
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
              const SizedBox(height: 2), // ← Réduit de 4 à 2
              Text(
                Formatters.formatCurrency(debt.amount),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13, // ← Ajouté taille réduite
                ),
              ),
              if (debt.phone != null) ...[
                const SizedBox(height: 2), // ← Réduit de 4 à 2
                GestureDetector(
                  onTap: () => _callNumber(debt.phone!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // ← Ajouté pour réduire largeur
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.blue.shade600), // ← Réduit de 14 à 12
                      const SizedBox(width: 4),
                      Text(
                        debt.phone!,
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                          fontSize: 12, // ← Ajouté taille réduite
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            padding: EdgeInsets.zero, // ← Ajouté pour réduire espace
            constraints: const BoxConstraints(), // ← Ajouté pour taille minimale
            icon: const Icon(Icons.more_vert, size: 20), // ← Ajouté taille réduite
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
                  height: 40, // ← Ajouté hauteur réduite
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 18), // ← Réduit de 20 à 18
                      SizedBox(width: 8),
                      Text('Appeler', style: TextStyle(fontSize: 13)), // ← Ajouté taille
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remind',
                height: 40, // ← Ajouté hauteur réduite
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18), // ← Réduit de 20 à 18
                    SizedBox(width: 8),
                    Text('Rappel', style: TextStyle(fontSize: 13)), // ← Texte raccourci
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'paid',
                height: 40, // ← Ajouté hauteur réduite
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: Colors.green), // ← Réduit de 20 à 18
                    SizedBox(width: 8),
                    Text('Payé', style: TextStyle(color: Colors.green, fontSize: 13)), // ← Texte raccourci
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

  void _markAllAsRead(BuildContext context) {
    DebtNotificationService().cancelAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été effacées'),
      ),
    );
  }
}