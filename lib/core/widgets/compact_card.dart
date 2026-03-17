import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/constants/app_colors.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';
import 'package:intl/intl.dart';

class CompactCard extends StatelessWidget {
  final String title; // Nom du produit ou description
  final String subtitle; // Date ou détails supplémentaires
  final double amount; // Montant
  final int quantity; // Quantité
  final bool isLocked; // Statut de verrouillage
  final VoidCallback onEdit; // Callback pour l'édition
  final VoidCallback onDelete; // Callback pour la suppression
  final Color amountColor; // Couleur du montant
  final Color? backgroundColor; // Couleur de fond optionnelle
  final bool showQuantityCircle; // Afficher le cercle de quantité
  final IconData? lockIcon; // Icône de verrouillage personnalisable
  final Color? lockIconColor; // Couleur de l'icône de verrouillage

  const CompactCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.quantity,
    required this.isLocked,
    required this.onEdit,
    required this.onDelete,
    required this.amountColor,
    this.backgroundColor,
    this.showQuantityCircle = true,
    this.lockIcon,
    this.lockIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cercle avec quantité OU icône de verrouillage
            if (showQuantityCircle)
              CircleAvatar(
                radius: 20,
                backgroundColor: amountColor.withOpacity(
                  0.15,
                ), // Remplacé par .withOpacity(0.15) si nécessaire
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              )
            else
              Icon(
                lockIcon ?? (isLocked ? Icons.lock : Icons.lock_open),
                color:
                    lockIconColor ??
                    (isLocked ? Colors.yellow.shade800 : Colors.grey.shade400),
                size: 20,
              ),
            const SizedBox(width: 12),

            // Titre + sous-titre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Montant + actions
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Montant
                  Text(
                    formatCFA(amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  // Quantité (si applicable)
                  if (quantity > 1 && showQuantityCircle)
                    Text(
                      '$quantity ×',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Icône de verrouillage + actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône de verrouillage
                      Icon(
                        lockIcon ?? (isLocked ? Icons.lock : Icons.lock_open),
                        size: 18,
                        color:
                            lockIconColor ??
                            (isLocked
                                ? Colors.yellow.shade800
                                : Colors.grey.shade400),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget spécialisé pour les ventes
class CompactSaleCard extends CompactCard {
  CompactSaleCard({
    super.key,
    required String productName,
    required double amount,
    required int quantity,
    required String date,
    required bool isLocked,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) : super(
         title: productName,
         subtitle: date,
         amount: amount,
         quantity: quantity,
         isLocked: isLocked,
         onEdit: onEdit,
         onDelete: onDelete,
         amountColor: Colors.green.shade700, // Couleur verte pour les ventes
         backgroundColor: Colors.green.shade50, // Fond vert clair
         showQuantityCircle: true,
       );
}

// Widget spécialisé pour les achats
class CompactPurchaseCard extends CompactCard {
  CompactPurchaseCard({
    super.key,
    required String productName,
    required double amount,
    required int quantity,
    required String date,
    required bool isLocked,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) : super(
         title: productName,
         subtitle: date,
         amount: amount,
         quantity: quantity,
         isLocked: isLocked,
         onEdit: onEdit,
         onDelete: onDelete,
         amountColor: Colors.blue.shade700, // Couleur bleue pour les achats
         backgroundColor: Colors.blue.shade50, // Fond bleu clair
         showQuantityCircle: true,
       );
}

// Widget spécialisé pour les dépenses
class CompactExpenseCard extends CompactCard {
  CompactExpenseCard({
    super.key,
    required String description,
    required double amount,
    required String date,
    required bool isLocked,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) : super(
         title: description,
         subtitle: date,
         amount: amount,
         quantity: 1, // Toujours 1 pour les dépenses
         isLocked: isLocked,
         onEdit: onEdit,
         onDelete: onDelete,
         amountColor:
             Colors.orange.shade700, // Couleur orange pour les dépenses
         backgroundColor: Colors.orange.shade50, // Fond orange clair
         showQuantityCircle: false, // Masquer le cercle pour les dépenses
       );
}

class AnnualDashboardCard extends StatelessWidget {
  final String month; // ex: "mars 2026"
  final double amount; // montant actuel
  final double previousAmount; // montant précédent
  final bool isIncrease; // true = hausse, false = baisse
  final Color amountColor; // couleur du montant principal
  final Color backgroundColor; // fond de la carte

  const AnnualDashboardCard({
    super.key,
    required this.month,
    required this.amount,
    required this.previousAmount,
    required this.isIncrease,
    required this.amountColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    final difference = amount - previousAmount;
    final diffPercentage = previousAmount != 0
        ? (difference / previousAmount) * 100
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mois + année
            Text(
              month.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Montant principal
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatter.format(amount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: amountColor,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Différence + pourcentage
            Row(
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncrease
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  previousAmount != 0
                      ? '${formatter.format(difference.abs())} (${diffPercentage.toStringAsFixed(1)}%)'
                      : 'Pas de données précédentes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isIncrease
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
