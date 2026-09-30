import 'package:facil_count_nouveau/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/subscription_plans_screen.dart';

class SubscriptionOverlay extends ConsumerWidget {
  final String? message;

  const SubscriptionOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // 🆕 POINT 2 : AppBar avec flèche de retour vers la page précédente
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Accès limité'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock,
                size: 80,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              "Accès Limité",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Text(
              message ??
                  "Votre période d'essai est arrivée à son terme ou votre abonnement a expiré. Pour continuer à gérer vos ventes et vos stocks, merci de choisir un forfait.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                child: const Text(
                  "DÉCOUVRIR LES FORFAITS",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Vérifier mon paiement"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vérification en cours...")),
                );
                await ref.read(authProvider.notifier).refreshSubscriptionStatus();
              },
            ),

            const SizedBox(height: 20),

            // 🆕 POINT 2 : Déconnexion → nettoie ET retourne au login
            TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
              child: Text(
                "Se déconnecter",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}