import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/invoice_provider.dart';
import 'widgets/invoice_card.dart';
import 'widgets/invoice_filter_chips.dart';
import 'invoice_detail_screen.dart';
import 'dialogs/add_invoice_dialog.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final stats = ref.watch(invoiceStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Factures'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) => Column(
          children: [
            // Stats rapides
            _buildStatsCard(stats),
            
            // Filtres
            const InvoiceFilterChips(),
            
            // Liste
            Expanded(
              child: invoices.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return InvoiceCard(
                          invoice: invoice,
                          onTap: () => _showInvoiceDetail(context, invoice),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddInvoiceDialog(context),
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Nouvelle'),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${stats['count']}', 'Factures', Icons.receipt),
          _buildStatItem(
            '${stats['total'].toStringAsFixed(0)}',
            'Total CFA',
            Icons.account_balance_wallet,
          ),
          _buildStatItem('${stats['payees']}', 'Payées', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune facture',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première facture',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context, invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

// Filter bottom sheet
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(invoiceStatusFilterProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'Tous',
              'Payée',
              'En attente',
              'Annulée',
            ].map((status) {
              final isSelected = statusFilter == status || 
                  (status == 'Tous' && statusFilter == null);
              
              return FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(invoiceStatusFilterProvider.notifier).state = 
                      status == 'Tous' ? null : status;
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}
