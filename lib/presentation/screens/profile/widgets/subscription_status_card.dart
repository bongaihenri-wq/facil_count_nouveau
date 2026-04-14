import 'package:flutter/material.dart';
import '/../../core/constants/app_colors.dart';

class SubscriptionStatusCard extends StatelessWidget {
  final DateTime createdAt;
  final bool isPremium;

  const SubscriptionStatusCard({
    super.key, 
    required this.createdAt, 
    this.isPremium = false
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalTrialDays = 30;
    final elapsedDays = now.difference(createdAt).inDays;
    final remainingDays = totalTrialDays - elapsedDays;
    
    // Calcul du pourcentage pour la barre de progression
    double progress = (remainingDays / totalTrialDays).clamp(0.0, 1.0);
    bool isExpired = remainingDays <= 0;
    bool showWarning = elapsedDays >= 7; // On affiche après 1 semaine

    if (!showWarning && !isPremium) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Statut du compte",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(isPremium, isExpired),
              ],
            ),
            const SizedBox(height: 16),
            if (!isPremium) ...[
              Text(
                isExpired 
                  ? "Votre essai a expiré" 
                  : "Il vous reste $remainingDays jours d'essai gratuit",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    remainingDays < 5 ? Colors.red : AppColors.primary,
                  ),
                ),
              ),
              if (isExpired) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { /* Future page de paiement */ },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Activer l'abonnement Pro"),
                  ),
                ),
              ],
            ] else 
              const Text("✨ Vous profitez de l'accès illimité Pro"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool premium, bool expired) {
    String label = premium ? "PRO" : (expired ? "EXPIRÉ" : "ESSAI");
    Color color = premium ? Colors.amber : (expired ? Colors.red : Colors.blue);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
