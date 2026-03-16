import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final supabase = Supabase.instance.client;

  Future<void> createSubscription({
    required String businessId,
    required DateTime endDate,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    await supabase.from('subscriptions').insert({
      'business_id': businessId,
      'end_date': endDate.toIso8601String(),
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
    });
  }

  Future<bool> checkActiveSubscription(String businessId) async {
    final res = await supabase
        .from('subscriptions')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'active')
        .gte('end_date', DateTime.now().toIso8601String())
        .maybeSingle();

    return res != null;
  }
}
