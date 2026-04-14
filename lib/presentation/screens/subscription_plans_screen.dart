import 'package:flutter/material.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choisir un forfait")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlanCard(
            context,
            title: "BASE",
            price: "1 000 CFA",
            color: Colors.blue,
            features: ["Ventes illimitées", "1 Utilisateur", "Rapports simples"],
            type: SubscriptionType.base,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context,
            title: "ELITE",
            price: "2 500 CFA",
            color: Colors.purple,
            features: ["Tout de Base", "Gestion de Stock", "Multi-utilisateurs"],
            isPopular: true,
            type: SubscriptionType.elite,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context,
            title: "PREMIUM",
            price: "5 000 CFA",
            color: Colors.amber.shade800,
            features: ["Tout d'Elite", "Dépenses avancées", "Support Prioritaire"],
            type: SubscriptionType.premium,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, {
    required String title,
    required String price,
    required Color color,
    required List<String> features,
    required SubscriptionType type,
    bool isPopular = false,
  }) {
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isPopular ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isPopular) const Text("PLUS POPULAIRE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 10),
            Text(price, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const Text("par mois"),
            const Divider(height: 30),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [const Icon(Icons.check, color: Colors.green), const SizedBox(width: 10), Text(f)]),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () {
                  // Ici tu lanceras ton interface de paiement (Orange Money / Moov / MTN)
                },
                child: const Text("S'abonner maintenant", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
