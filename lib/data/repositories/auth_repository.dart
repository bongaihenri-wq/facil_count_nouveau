import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🟢 Récupérer le profil complet (User + Subscription)
  Future<UserModel?> getFullProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // On fait une jointure pour récupérer l'utilisateur et son abonnement actif
      final response = await _supabase
          .from('users')
          .select('*, subscriptions(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      // On prépare le Map pour le factory UserModel.fromJson
      final Map<String, dynamic> data = Map.from(response);
      
      // On extrait l'abonnement actif de la liste retournée par la jointure
      if (data['subscriptions'] != null && (data['subscriptions'] as List).isNotEmpty) {
        // On cherche celui qui est 'active'
        final activeSub = (data['subscriptions'] as List).firstWhere(
          (s) => s['status'] == 'active',
          orElse: () => data['subscriptions'][0],
        );
        data['subscription'] = activeSub;
      }

      return UserModel.fromJson(data);
    } catch (e) {
      print('❌ Erreur AuthRepository (getFullProfile): $e');
      return null;
    }
  }

  // 🟢 Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
