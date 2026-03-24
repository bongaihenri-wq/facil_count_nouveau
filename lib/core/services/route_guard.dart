import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/services/auth_service.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const RouteGuard({
    super.key,
    required this.child,
    this.requiredRole = 'user',
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (requiredRole != 'user') {
          // ✅ CORRIGÉ : FutureBuilder<String?> au lieu de FutureBuilder<String>
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // ✅ CORRIGÉ : Vérification avec gestion du null
              if (roleSnapshot.data != requiredRole &&
                  roleSnapshot.data != null) {
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

        return child;
      },
    );
  }
}
