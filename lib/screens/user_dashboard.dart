import 'package:flutter/material.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord Utilisateur')),
      body: const Center(child: Text('Bienvenue sur votre tableau de bord!')),
    );
  }
}
