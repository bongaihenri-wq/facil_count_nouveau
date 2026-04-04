import 'package:flutter/material.dart';
import '/data/models/invoice_model.dart';
// 💡 Note : Ajuste bien ce chemin selon la structure exacte de ton projet si besoin !
import '/core/utils/formatters.dart'; 

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1, // Un peu plus discret et moderne que 2
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image miniature ou icône
              _buildThumbnail(),
              const SizedBox(width: 14),
              
              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne type + numéro + statut
                    Row(
                      children: [
                        _buildTypeBadge(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            // 🟢 CORRECTION : On gère le cas où le numéro est null
                            invoice.number ?? 'Sans numéro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: invoice.number == null ? Colors.grey : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Date + fournisseur
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          // On utilise ton formateur de date
                          Formatters.formatDate(invoice.invoiceDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (invoice.supplier != null && invoice.supplier!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              invoice.supplier!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Montant
                    Text(
                      Formatters.formatCurrency(invoice.amount),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _getAmountColor(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche + icône verrou
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (invoice.locked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Icon(Icons.lock, color: Colors.orange.shade700, size: 18),
                    ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final hasImage = invoice.imageUrl != null && invoice.imageUrl!.isNotEmpty;
    
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasImage
            ? Image.network(
                invoice.imageUrl!,
                fit: BoxFit.cover,
                // Évite l'effet d'apparition brusque de l'image
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, color: Colors.grey.shade400, size: 28);
                },
              )
            : Icon(Icons.receipt_long, color: Colors.grey.shade400, size: 28),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final colors = {
      'Achats': Colors.blue.shade700,
      'Ventes': Colors.green.shade700,
      'Dépenses': Colors.orange.shade700,
    };
    
    final color = colors[invoice.type] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        invoice.type.substring(0, 3).toUpperCase(), // Abrégé en majuscule : ACH, VEN, DEP
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final colors = {
      'Payée': Colors.green,
      'En attente': Colors.orange,
      'Annulée': Colors.red,
    };
    
    final color = colors[invoice.status] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        invoice.status,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getAmountColor() {
    return switch (invoice.type) {
      'Achats' => Colors.red.shade700,
      'Ventes' => Colors.green.shade700,
      'Dépenses' => Colors.orange.shade800,
      _ => Colors.black87,
    };
  }
}