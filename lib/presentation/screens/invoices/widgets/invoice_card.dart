import 'package:flutter/material.dart';
import '/data/models/invoice_model.dart';
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
      elevation: 2,
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
                            invoice.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                          Formatters.formatDate(invoice.invoiceDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (invoice.supplier != null) ...[
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
                        fontSize: 18,
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
                      child: Icon(Icons.lock, color: Colors.orange.shade700, size: 20),
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
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: hasImage ? null : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(invoice.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Icon(Icons.receipt_long, color: Colors.grey.shade400, size: 32)
          : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        invoice.type.substring(0, 3), // Abrégé: Ach, Ven, Dép
        style: TextStyle(
          color: color,
          fontSize: 11,
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
          fontWeight: FontWeight.w600,
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
