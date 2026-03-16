import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/services/auth_service.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const RouteGuard({
    super.key,
    required this.child,
    this.requiredRole =
        'user', // Par défaut, tout utilisateur connecté peut accéder
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, isLoggedInSnapshot) {
        if (isLoggedInSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (isLoggedInSnapshot.data != true) {
          // Si l'utilisateur n'est pas connecté, rediriger vers la page de connexion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si une vérification de rôle est nécessaire
        if (requiredRole != 'user') {
          return FutureBuilder<String>(
            future: AuthService().getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.data != requiredRole) {
                // Si le rôle n'est pas celui requis, rediriger vers une page d'erreur ou la page d'accueil
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/home');
                });
                return const Scaffold(
                  body: Center(child: Text('Accès non autorisé')),
                );
              }

              return child;
            },
          );
        }

        // Si tout est OK, afficher la page demandée
        return child;
      },
    );
  }
}
