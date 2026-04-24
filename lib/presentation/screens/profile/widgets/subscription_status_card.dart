import 'package:flutter/material.dart';
import '/../../data/models/user_model.dart';
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
              const Text("Abonnement Expire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              _planTile(context, "Base", "1 000 CFA", Colors.blue),
              _planTile(context, "Elite", "2 500 CFA", Colors.orange),
              _planTile(context, "Premium", "5 000 CFA", Colors.purple),
            ] else ...[
              const Text("Version d'essai active"),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SubscriptionPlansScreen())),
                child: const Text("Passer à la version Pro"),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _planTile(BuildContext context, String name, String price, Color color) {
    return ListTile(
      leading: Icon(Icons.star, color: color),
      title: Text(name),
      subtitle: Text(price),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => ManualPaymentDialog(planTitle: name, amount: price),
      ),
    );
  }
}