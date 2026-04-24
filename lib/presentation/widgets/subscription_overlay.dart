import 'package:facil_count_nouveau/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Nécessaire pour ConsumerWidget
import '../screens/subscription_plans_screen.dart';

// On change StatelessWidget en ConsumerWidget pour accéder à "ref"
class SubscriptionOverlay extends ConsumerWidget {
  final String? message;

  const SubscriptionOverlay({
    super.key,
    this.message,
  });

  @override
  // On ajoute WidgetRef ref ici
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
            // Icône stylisée
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

            // Titre principal
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

            // Message explicatif
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

            // Bouton d'action principal
            SArea(
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

            // Bouton de rafraîchissement (Maintenant fonctionnel avec ref)
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Vérifier mon paiement"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
              onPressed: () async {
                // Affiche un petit indicateur visuel
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vérification en cours...")),
                );
                
                // Appelle la fonction de rafraîchissement
                await ref.read(authProvider.notifier).refreshSubscriptionStatus();
              },
            ),

            const SizedBox(height: 20),

            // Bouton de déconnexion (Activé lui aussi)
            TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
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

// Widget utilitaire inchangé
class SArea extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  const SArea(
      {super.key,
      required this.child,
      required this.width,
      required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}
