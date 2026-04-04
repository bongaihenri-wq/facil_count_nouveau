import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/data/models/invoice_model.dart';
import '/presentation/providers/invoice_provider.dart';
import '../dialogs/invoice_form_dialog.dart'; // Pour appeler l'édition

class InvoiceDetailScreen extends ConsumerWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          invoice.number != null ? 'Facture ${invoice.number}' : 'Détails Facture',
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton Modifier
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editInvoice(context),
          ),
          // Bouton Supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 SECTION IMAGE AVEC ZOOM INTERACTIF
            _buildImageSection(context),
            const SizedBox(height: 20),

            // SECTION INFORMATIONS
            _buildInfoCard(),
            const SizedBox(height: 16),

            // SECTION NOTES
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  /// Widget pour l'image avec un effet de pincement pour zoomer
  Widget _buildImageSection(BuildContext context) {
    if (invoice.imageUrl == null || invoice.imageUrl!.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Aucune photo attachée',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu (Pincez pour zoomer)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 350,
            width: double.infinity,
            color: Colors.white,
            // 🔄 InteractiveViewer permet de zoomer et de se déplacer dans l'image !
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                invoice.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.red),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Carte contenant les détails textuels de la facture
  Widget _buildInfoCard() {
    final formattedDate = '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            label: 'Type',
            value: invoice.type,
            icon: _getTypeIcon(),
            iconColor: _getTypeColor(),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            label: 'Montant',
            value: '${invoice.amount.toStringAsFixed(0)} CFA',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.purple,
            isBoldValue: true,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            label: 'Date',
            value: formattedDate,
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            label: 'Statut',
            value: invoice.status,
            icon: invoice.status == 'Payée' ? Icons.check_circle : Icons.pending,
            iconColor: invoice.status == 'Payée' ? Colors.green : Colors.orange,
          ),
          if (invoice.supplier != null && invoice.supplier!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildDetailRow(
              label: 'Fournisseur / Client',
              value: invoice.supplier!,
              icon: Icons.business,
              iconColor: Colors.grey.shade700,
            ),
          ],
        ],
      ),
    );
  }

  /// Carte dédiée aux notes de la facture
  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            invoice.notes!,
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Génère une ligne de détail uniforme
  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isBoldValue = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    return switch (invoice.type) {
      'Achats' => Icons.shopping_cart,
      'Ventes' => Icons.point_of_sale,
      'Dépenses' => Icons.money_off,
      _ => Icons.receipt,
    };
  }

  Color _getTypeColor() {
    return switch (invoice.type) {
      'Achats' => Colors.blue,
      'Ventes' => Colors.green,
      'Dépenses' => Colors.orange,
      _ => Colors.grey,
    };
  }

  /// 🟢 Déclenche l'ouverture de l'édition avec notre dialogue dynamique !
  void _editInvoice(BuildContext context) {
    showInvoiceDialog(context, invoice: invoice);
  }

  /// Pop-up de confirmation avant suppression
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la facture ?'),
        content: const Text('Cette action est irréversible. Voulez-vous continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Ferme la boîte de dialogue
              
              final notifier = ref.read(invoiceNotifierProvider.notifier);
              await notifier.deleteInvoice(invoice.id);
              
              if (context.mounted) {
                Navigator.pop(context); // Revient à l'écran précédent (InvoicesScreen)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Facture supprimée !'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}