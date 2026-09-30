import 'package:flutter/material.dart';
import '/../../data/models/user_model.dart';
import '/../../data/models/subscription_model.dart';
import '/../../presentation/widgets/manual_payment_dialog.dart';
import '/../../presentation/screens/subscription_plans_screen.dart';

class SubscriptionStatusCard extends StatelessWidget {
  final UserModel user;

  const SubscriptionStatusCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isExpired = user.isTrialExpired;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isExpired) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const Text("Abonnement Expiré",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              // 🆕 4 forfaits aux bons prix
              _planTile(context, "Base", "1 000 CFA", Colors.blue, SubscriptionType.base),
              _planTile(context, "Medium", "2 500 CFA", Colors.teal, SubscriptionType.medium),
              _planTile(context, "Elite", "5 000 CFA", Colors.purple, SubscriptionType.elite),
              _planTile(context, "Premium", "10 000 CFA", Colors.amber.shade800, SubscriptionType.premium),
            ] else ...[
              const Text("Version d'essai active"),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => const SubscriptionPlansScreen())),
                child: const Text("Passer à la version Pro"),
              )
            ]
          ],
        ),
      ),
    );
  }

  // 🆕 Ajout du paramètre type + gestion du résultat du dialogue
  Widget _planTile(BuildContext context, String name, String price, Color color, SubscriptionType type) {
    return ListTile(
      leading: Icon(Icons.star, color: color),
      title: Text(name),
      subtitle: Text(price),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => ManualPaymentDialog(
            planType: type,
            planTitle: name,
            amount: price,
          ),
        );
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "✅ Demande envoyée ! Activation après vérification du paiement.")),
          );
        }
      },
    );
  }
}