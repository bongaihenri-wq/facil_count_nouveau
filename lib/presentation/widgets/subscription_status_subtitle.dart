import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/payment_service.dart';
import '../../presentation/providers/subscription_provider.dart';

class SubscriptionStatusSubtitle extends ConsumerWidget {
  const SubscriptionStatusSubtitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysRemaining = ref.watch(daysRemainingProvider);
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

    return subscriptionAsync.when(
      data: (sub) {
        String text;
        Color color;

        if (!sub.isValid) {
          text = 'Expiré - Renouvelez maintenant';
          color = AppColors.error;
        } else if (sub.isTrial) {
          text = 'Essai: $daysRemaining jours restants';
          color = AppColors.accent;
        } else if (daysRemaining <= 7) {
          text = 'Expire dans $daysRemaining jours';
          color = AppColors.warning;
        } else {
          text = '${PaymentService.getLabel(sub.type)} - $daysRemaining jours';
          color = AppColors.textSecondary;
        }

        return Text(
          text,
          style: TextStyle(color: color, fontSize: 12),
        );
      },
      loading: () => const Text('Chargement...'),
      error: (_, __) => const Text('Erreur de chargement'),
    );
  }
}