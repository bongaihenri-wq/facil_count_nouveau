// lib/core/services/debt_notification_service.dart
import '../../data/models/cash_models.dart';

class DebtNotificationService {
  static final DebtNotificationService _instance =
      DebtNotificationService._internal();
  factory DebtNotificationService() => _instance;
  DebtNotificationService._internal();

  Future<void> initialize() async {
    // Notifications désactivées
  }

  Future<void> checkOverdueDebts(List<DebtInfo> debts) async {
    // Notifications désactivées
  }

  Future<void> cancelAll() async {
    // Notifications désactivées
  }
}
