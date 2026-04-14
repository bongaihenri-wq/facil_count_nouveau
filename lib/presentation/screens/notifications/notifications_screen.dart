import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Alerte Abonnement (Si nécessaire)
                if (user.hasSubscriptionAlert || user.isTrialExpired)
                  _buildSubscriptionAlert(user),

                const SizedBox(height: 8),

                // 2. Section Titre pour les autres notifications
                const Text(
                  "Activités récentes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Simulation de notifications vides ou existantes
                _buildEmptyState(),
              ],
            ),
    );
  }

  Widget _buildSubscriptionAlert(user) {
    final bool expired = user.isTrialExpired;
    final int days = user.trialDaysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: expired 
            ? [Colors.red.shade700, Colors.red.shade400] 
            : [Colors.orange.shade700, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (expired ? Colors.red : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.star, color: Colors.white),
        ),
        title: Text(
          expired ? "Essai terminé" : "Fin de l'essai bientôt",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          expired 
            ? "Votre accès est restreint. Activez votre abonnement Pro." 
            : "Il ne vous reste que $days jours. Pensez à vous abonner.",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        onTap: () {
          // Naviguer vers la page de paiement ou de profil
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Aucune nouvelle notification",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
