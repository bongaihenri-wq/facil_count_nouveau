import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dbcrypt/dbcrypt.dart'; // 🟢 Ajout pour le hashage sécurisé
import '../../data/models/user_model.dart';

class UserService {
  final supabase = Supabase.instance.client;

  /// Récupère la liste des utilisateurs liés à un commerce
  Future<List<UserModel>> getUsersByBusiness(String businessId) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('business_id', businessId);

    return (res as List).map((user) => UserModel.fromJson(user)).toList();
  }

  /// Verrouille ou déverrouille un utilisateur
  Future<void> lockUser(String userId, bool locked) async {
    await supabase
        .from('users')
        .update({'is_active': !locked})
        .eq('id', userId);
  }

  /// 🟢 Vérification sécurisée avec hashage
  Future<bool> verifyAdminPasswordSecure(String adminId, String password) async {
    final admin = await supabase
        .from('users')
        .select('password')
        .eq('id', adminId)
        .maybeSingle();

    if (admin == null) return false;

    final String storedHash = admin['password'];

    try {
      // 🟢 Vérifie si le mot de passe correspond au hash stocké
      return DBCrypt().checkpw(password, storedHash);
    } catch (e) {
      // Si l'ancien mot de passe était stocké en clair (transition), on fait une vérification basique
      return storedHash == password;
    }
  }

  /// 🟢 Bonus : Méthode pour créer ou modifier un mot de passe en le hashant
  String hashPassword(String password) {
  // On utilise logRounds au lieu de cost
  return DBCrypt().hashpw(password, DBCrypt().gensalt());
}
}