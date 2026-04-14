import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionRepository {
  final _supabase = Supabase.instance.client;

  // 🟢 Récupérer l'abonnement en cours pour un business
  Future<SubscriptionModel?> getActiveSubscription(String businessId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('business_id', businessId)
          .eq('status', 'active') // On ne prend que l'actif
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SubscriptionModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur SubscriptionRepository (fetch): $e');
      return null;
    }
  }

  // 🟢 Enregistrer un nouveau paiement (Orange Money, etc.)
  Future<bool> createSubscription(SubscriptionModel sub) async {
    try {
      await _supabase.from('subscriptions').insert(sub.toJson());
      return true;
    } catch (e) {
      print('❌ Erreur SubscriptionRepository (create): $e');
      return false;
    }
  }
}
