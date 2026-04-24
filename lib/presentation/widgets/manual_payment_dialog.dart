// lib/presentation/screens/subscription/manual_payment_dialog.dart

import 'package:flutter/material.dart';

class ManualPaymentDialog extends StatelessWidget {
  final String planTitle;
  final String amount;

  const ManualPaymentDialog({super.key, required this.planTitle, required this.amount});

  @override
  Widget build(BuildContext context) {
    final TextEditingController refController = TextEditingController();

    return AlertDialog(
      title: Text("Paiement Forfait $planTitle"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Effectuez le transfert de :", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$amount CFA", style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("2. Vers l'un des numéros suivants :"),
            const Text("• Orange : 07 49 63 55 22 (Nom)"),
            const Text("• Mtn : 05 06 43 29 43 (Nom)"),
            const SizedBox(height: 15),
            const Text("3. Entrez la référence du transfert :", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                hintText: "Ex: PP230415.1234.C45678",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            // Ici, tu envoies la refController.text à ton backend ou via WhatsApp
            print("Référence envoyée : ${refController.text}");
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Référence envoyée ! Votre compte sera activé après vérification."))
            );
          },
          child: const Text("Valider"),
        ),
      ],
    );
  }
}