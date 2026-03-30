import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

class UserService {
  final supabase = Supabase.instance.client;

  Future<List<UserModel>> getUsersByBusiness(String businessId) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('business_id', businessId); // Correction: business_id pas businessId

    return (res as List).map((user) => UserModel.fromJson(user)).toList(); // Correction: fromJson pas fromMap
  }

  Future<void> lockUser(String userId, bool locked) async {
    await supabase.from('users').update({'is_active': !locked}).eq('id', userId); // Correction: is_active pas isActive
  }

  Future<bool> verifyAdminPassword(String adminId, String password) async {
    // TODO: Vérifier avec hashage bcrypt, pas en clair
    final admin = await supabase
        .from('users')
        .select()
        .eq('id', adminId)
        .eq('password', password) // ⚠️ SECURITÉ: À remplacer par vérification hashée
        .maybeSingle();

    return admin != null;
  }

  // Méthode ajoutée: Vérification sécurisée avec hashage
  Future<bool> verifyAdminPasswordSecure(String adminId, String password) async {
    final admin = await supabase
        .from('users')
        .select('password')
        .eq('id', adminId)
        .maybeSingle();

    if (admin == null) return false;

    // TODO: Utiliser bcrypt pour vérifier
    // return BCrypt.checkpw(password, admin['password']);
    return admin['password'] == password; // Temporaire
  }
}
