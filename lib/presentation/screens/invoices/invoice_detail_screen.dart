import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/invoice_provider.dart';
import 'widgets/invoice_image_viewer.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ✅ HEADER AVEC INFOS (overlay transparent)
          _buildHeader(context, ref),
          
          // ✅ IMAGE ZOOMABLE (prend tout l'espace)
          Expanded(
            child: InvoiceImageViewer(
              imageUrl: invoice.imageUrl,
              placeholder: _buildPlaceholder(),
            ),
          ),
          
          // ✅ BARRE D'ACTIONS EN BAS
          _buildBottomBar(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne du haut : retour + actions
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                if (invoice.locked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Verrouillée',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: Colors.grey.shade900,
                    onSelected: (value) => _handleMenuAction(context, ref, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Modifier', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Partager', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Type + Numéro
            Row(
              children: [
                _buildTypeBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'N° ${invoice.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Montant (gros)
            Text(
              Formatters.formatCurrency(invoice.amount),
              style: TextStyle(
                color: _getAmountColor(),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Date + Fournisseur
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  Formatters.formatDate(invoice.invoiceDate),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (invoice.supplier != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.business, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      invoice.supplier!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (invoice.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invoice.notes!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    final isPaid = invoice.status == 'Payée';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: isPaid ? Icons.check_circle : Icons.pending,
              label: isPaid ? 'Payée' : 'En attente',
              color: isPaid ? Colors.green : Colors.orange,
              onTap: () => _toggleStatus(context, ref),
            ),
            _buildActionButton(
              icon: Icons.edit,
              label: 'Modifier',
              color: Colors.blue,
              onTap: () => _editInvoice(context),
            ),
            _buildActionButton(
              icon: Icons.delete,
              label: 'Supprimer',
              color: Colors.red,
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final colors = {
      'Achats': Colors.blue,
      'Ventes': Colors.green,
      'Dépenses': Colors.orange,
    };
    
    final color = colors[invoice.type] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        invoice.type,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hide_image, size: 100, color: Colors.grey.shade700),
          const SizedBox(height: 20),
          const Text(
            'Aucune image disponible',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getAmountColor() {
    return switch (invoice.type) {
      'Achats' => Colors.red.shade300,
      'Ventes' => Colors.green.shade300,
      'Dépenses' => Colors.orange.shade300,
      _ => Colors.white,
    };
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'edit':
        _editInvoice(context);
        break;
      case 'share':
        _shareInvoice(context);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final newStatus = invoice.status == 'Payée' ? 'En attente' : 'Payée';
    
    try {
      await ref.read(invoiceNotifierProvider.notifier)
          .updateStatus(invoice.id, newStatus);
      
      ref.invalidate(invoicesProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: $newStatus'),
            backgroundColor: newStatus == 'Payée' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editInvoice(BuildContext context) {
    // TODO: Ouvrir dialog d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition à implémenter')),
    );
  }

  void _shareInvoice(BuildContext context) {
    // TODO: Implémenter partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à implémenter')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Supprimer ?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Supprimer la facture ${invoice.number} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(invoiceNotifierProvider.notifier).deleteInvoice(invoice.id);
        
        // Supprimer l'image si présente
        if (invoice.imageUrl != null) {
          await ref.read(invoiceRepositoryProvider).deleteImage(invoice.imageUrl!);
        }
        
        ref.invalidate(invoicesProvider);
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facture supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}