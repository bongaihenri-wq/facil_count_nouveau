import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessRepository {
  final _client = Supabase.instance.client;

  /// Les boutiques du compte connecté
  Future<List<Map<String, dynamic>>> getMyBusinesses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('user_businesses')
        .select('business_id, businesses(id, name, code)')
        .eq('user_id', userId);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Change la boutique active (DB + JWT)
  Future<void> switchBusiness(String businessId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('users')
        .update({'business_id': businessId})
        .eq('id', userId);
    await _client.auth
        .updateUser(UserAttributes(data: {'business_id': businessId}));
    await _client.auth.refreshSession();
  }

  /// Ajoute une boutique au compte connecté
  Future<Map<String, dynamic>> addBusiness(String name, String type) async {
    final res = await _client.functions.invoke('add-business',
        body: {'businessName': name, 'businessType': type});
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Erreur création boutique');
    }
    return res.data as Map<String, dynamic>;
  }
}