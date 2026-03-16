import 'package:flutter/material.dart';

class LockedWidget extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback onUnlock;

  const LockedWidget({
    super.key,
    required this.child,
    required this.isLocked,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) {
      return child;
    }

    return Stack(
      children: [
        Opacity(opacity: 0.5, child: child),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Élément verrouillé'),
                    content: const Text(
                      'Cet élément est verrouillé. Veuillez entrer le mot de passe admin pour le déverrouiller.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: onUnlock,
                        child: const Text('Déverrouiller'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: Icon(Icons.lock, color: Colors.orange),
        ),
      ],
    );
  }
}
