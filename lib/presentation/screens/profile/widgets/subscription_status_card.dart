import 'package:facil_count_nouveau/data/models/subscription_model.dart';
import 'package:facil_count_nouveau/data/models/user_model.dart';
import 'package:flutter/material.dart';
import '/../../core/constants/app_colors.dart';

class SubscriptionStatusCard extends StatelessWidget {
  final UserModel user; // On passe le user complet pour plus de flexibilité

  const SubscriptionStatusCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final sub = user.subscription;
    
    // Cas 1 : L'utilisateur a un abonnement actif (Base, Elite, Premium)
    if (sub != null && sub.isValid && !sub.isTrial) {
      return _buildActiveSubCard(sub);
    }

    // Cas 2 : L'utilisateur est en période d'essai (les 30 premiers jours)
    return _buildTrialCard();
  }

  Widget _buildActiveSubCard(SubscriptionModel sub) {
    return Card(
      elevation: 0,
      color: _getPlanColor(sub.type).withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _getPlanColor(sub.type).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: _getPlanColor(sub.type)),
                const SizedBox(width: 8),
                Text(
                  "PLAN ${sub.type.name.toUpperCase()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _getPlanColor(sub.type)
                  ),
                ),
                const Spacer(),
                Text("${sub.daysRemaining} jours restants"),
              ],
            ),
            if (sub.isInGracePeriod) ...[
              const SizedBox(height: 8),
              Text(sub.alertMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTrialCard() {
    final remaining = user.trialDaysRemaining;
    final isExpired = user.isTrialExpired;

    return Card(
      // ... (Ta logique de barre de progression actuelle) ...
      // Mais avec une option pour choisir les 3 paliers :
      child: Column(
        children: [
           // ... (Entête de ta carte actuelle) ...
           if (isExpired) 
             _buildPlanSelector(), // 🟢 On propose les 3 choix directement
        ],
      ),
    );
  }

  // Helper pour les couleurs de palier
  Color _getPlanColor(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.premium: return Colors.purple;
      case SubscriptionType.elite: return Colors.amber.shade700;
      case SubscriptionType.base: return AppColors.primary;
      default: return Colors.blue;
    }
  }

  Widget _buildPlanSelector() {
    return Column(
      children: [
        const Text("Choisissez votre palier pour continuer :"),
        const SizedBox(height: 12),
        _planTile("Base", "1 000 CFA", Colors.blue),
        _planTile("Elite", "2 500 CFA", Colors.amber),
        _planTile("Premium", "5 000 CFA", Colors.purple),
      ],
    );
  }

  Widget _planTile(String name, String price, Color color) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.star, color: color),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      onTap: () { /* Action de paiement */ },
    );
  }
}