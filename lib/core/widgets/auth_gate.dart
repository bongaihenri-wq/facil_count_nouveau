import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';

/// 🛡️ Bloque l'accès aux écrans si non authentifié
class AuthGate extends ConsumerStatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Restaure la session au démarrage
    Future.microtask(() async {
      await ref.read(authProvider.notifier).initialize();
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return const LoginScreen();
    return widget.child;
  }
}