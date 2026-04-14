import 'package:flutter/material.dart';
import '../screens/subscription_plans_screen.dart'; // Import de ta page de tarifs

class SubscriptionOverlay extends StatelessWidget {
  final String? message;

  const SubscriptionOverlay({
    super.key, 
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On utilise un Container avec un léger dégradé pour un look pro
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
              message ?? "Votre période d'essai est arrivée à son terme ou votre abonnement a expiré. Pour continuer à gérer vos ventes et vos stocks, merci de choisir un forfait.",
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
                  // Navigation vers la page des 3 plans (Base, Elite, Premium)
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
            
            const SizedBox(height: 20),
            
            // Petit bouton discret pour se déconnecter au cas où
            TextButton(
              onPressed: () {
                // Ici tu peux appeler ton authProvider pour déconnecter
                // ref.read(authProvider.notifier).logout();
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

// Widget utilitaire pour limiter la largeur sur tablette/web
class SArea extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  const SArea({super.key, required this.child, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}
