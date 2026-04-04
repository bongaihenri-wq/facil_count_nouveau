import 'package:facil_count_nouveau/presentation/screens/invoices/widgets/invoice_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import 'dialogs/invoice_form_dialog.dart'; 

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
            onPressed: () => showInvoiceDialog(context, invoice: invoice),
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
            _buildInfoCard(context, ref),
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
 /// Widget pour l'image avec ouverture plein écran au clic et zoom
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

    // Le placeholder à afficher pendant le chargement dans la visionneuse
    final Widget placeholder = Container(
      height: 350,
      width: double.infinity,
      color: Colors.white,
      child: const Center(child: CircularProgressIndicator()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu (Cliquez pour agrandir)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        // 🟢 Détecteur de clic pour ouvrir l'image en plein écran
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  body: InvoiceImageViewer(
                    imageUrl: invoice.imageUrl,
                    placeholder: placeholder,
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 350,
              width: double.infinity,
              color: Colors.white,
              // Ici, on garde l'InteractiveViewer pour un petit zoom rapide directement sur l'écran
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 2.5, 
                child: Image.network(
                  invoice.imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return placeholder;
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
        ),
      ],
    );
  }

  /// Carte contenant les détails textuels de la facture
  Widget _buildInfoCard(BuildContext context, WidgetRef ref) {
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
          
          // Ligne de statut avec un bouton pour changer à la volée
          Row(
            children: [
              _buildDetailRow(
                label: 'Statut',
                value: invoice.status,
                icon: invoice.status == 'Payée' ? Icons.check_circle : Icons.pending,
                iconColor: invoice.status == 'Payée' ? Colors.green : Colors.orange,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showStatusPicker(context, ref),
                child: const Text('Changer'),
              ),
            ],
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
      mainAxisSize: MainAxisSize.min,
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
        Column(
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

 /// 🟢 Ouvre un menu pour changer le statut et rafraîchit l'écran
  void _showStatusPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // On applique ici aussi le padding de bas de page dont on parlait !
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Wrap(
              children: ['En attente', 'Payée', 'Annulée'].map((status) {
                // Définition de la couleur selon le statut pour le design
                final Color statusColor = status == 'Payée' 
                    ? Colors.green 
                    : (status == 'Annulée' ? Colors.red : Colors.orange);
                    
                return ListTile(
                  title: Text(
                    status,
                    style: TextStyle(
                      fontWeight: invoice.status == status ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    status == 'Payée' ? Icons.check_circle : Icons.pending,
                    color: statusColor,
                  ),
                  trailing: invoice.status == status 
                      ? const Icon(Icons.check, color: Colors.purple) 
                      : null,
                  onTap: () async {
                    Navigator.pop(context); // Ferme le menu
                    
                    if (invoice.status == status) return; // Aucun changement
                    
                    // 1. On crée une copie de la facture avec le nouveau statut
                    final updatedInvoice = invoice.copyWith(status: status);
                    
                    // 2. On lance la mise à jour dans Supabase
                    await ref.read(invoiceNotifierProvider.notifier).updateInvoice(updatedInvoice);
                    
                    // 3. On force Riverpod à rafraîchir la liste générale
                    ref.invalidate(invoicesFutureProvider);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Statut mis à jour : "$status"'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      // 🔥 TRUC ET ASTUCE : On recharge l'écran de détails en revenant en arrière
                      // et en se ré-ouvrant avec la facture mise à jour !
                      Navigator.pop(context); // Quitte l'écran de détails actuel
                      
                      // Optionnel : Si tu veux le réouvrir automatiquement mis à jour :
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceDetailScreen(invoice: updatedInvoice),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
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
              
              // 🟢 Correction : Suppression physique de l'image si elle existe
              if (invoice.imageUrl != null && invoice.imageUrl!.isNotEmpty) {
                await ref.read(invoiceRepositoryProvider).deleteImage(invoice.imageUrl!);
              }
              
              // Suppression de la facture en BDD
              await ref.read(invoiceNotifierProvider.notifier).deleteInvoice(invoice.id);
              
              // Rafraîchissement avec le BON provider
              ref.invalidate(invoicesFutureProvider);
              
              if (context.mounted) {
                Navigator.pop(context); // Revient à la liste
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