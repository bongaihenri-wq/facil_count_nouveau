import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_support_service.dart';

/// Bouton flottant support WhatsApp pour les testeurs
class SupportFAB extends StatelessWidget {
  final String? currentScreen;

  const SupportFAB({super.key, this.currentScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton feedback
        FloatingActionButton.small(
          heroTag: 'feedback',
          onPressed: () => _showFeedbackDialog(context),
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.feedback, color: Colors.white),
        ),
        const SizedBox(height: 8),
        // Bouton support WhatsApp
        FloatingActionButton.extended(
          heroTag: 'whatsapp',
          onPressed: () => WhatsAppSupportService.openSupport(screenName: currentScreen),
          backgroundColor: const Color(0xFF25D366), // Vert WhatsApp
          icon: const Icon(Icons.chat, color: Colors.white),
          label: const Text('Aide', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Votre avis'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Que pensez-vous de l\'app ?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              WhatsAppSupportService.sendFeedback(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
