import 'package:flutter/material.dart';
import '../../data/models/subscription_model.dart';
import '../widgets/manual_payment_dialog.dart'; // Import du dialogue de paiement

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir un forfait"),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Boostez votre gestion commerciale avec nos forfaits adaptés",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            _buildPlanCard(
              context,
              title: "BASE",
              price: "2 500 CFA",
              color: Colors.blue,
              features: ["Ventes illimitées", "1 Utilisateur", "Rapports simples"],
              type: SubscriptionType.base,
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              context,
              title: "ELITE",
              price: "5 000 CFA",
              color: Colors.purple,
              features: ["Tout de Base", "Gestion de Stock", "Multi-utilisateurs"],
              isPopular: true,
              type: SubscriptionType.elite,
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              context,
              title: "PREMIUM",
              price: "10 000 CFA",
              color: Colors.amber.shade800,
              features: ["Tout d'Elite", "Dépenses avancées", "Support Prioritaire"],
              type: SubscriptionType.premium,
            ),
            const SizedBox(height: 30),
          ],
        ),
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
    return Stack(
      children: [
        Card(
          elevation: isPopular ? 12 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isPopular ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: color,
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text(" / mois", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // 🟢 REDIRECTION VERS LE DIALOGUE DE PAIEMENT MANUEL
                      showDialog(
                        context: context,
                        builder: (context) => ManualPaymentDialog(
                          planTitle: title,
                          amount: price,
                        ),
                      );
                    },
                    child: const Text(
                      "S'abonner maintenant",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Text(
                "POPULAIRE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
