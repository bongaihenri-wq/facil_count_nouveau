import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/data/models/user_model.dart' as user_model;
import 'package:facil_count_nouveau/data/models/business_model.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<user_model.User> registerUser({
    required String phoneNumber,
    required String password,
    required String businessName,
    required String businessType,
    required bool isAdmin,
  }) async {
    try {
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Ce numéro de téléphone est déjà utilisé.');
      }

      final businessRes = await supabase
          .from('businesses')
          .insert({'name': businessName, 'type': businessType})
          .select()
          .maybeSingle();

      if (businessRes == null) {
        throw Exception('Erreur lors de la création du commerce.');
      }

      final business = BusinessModel.fromJson(businessRes);

      final userRes = await supabase
          .from('users')
          .insert({
            'phone_number': phoneNumber,
            'password': password,
            'business_id': business.id,
            'role': isAdmin ? 'admin' : 'user',
          })
          .select()
          .maybeSingle();

      if (userRes == null) {
        throw Exception('Erreur lors de la création de l\'utilisateur.');
      }

      // ✅ CORRIGÉ : user_model.User.fromMap
      return user_model.User.fromMap(userRes);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de l\'enregistrement: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement: $e');
    }
  }

  Future<user_model.User> login(String phoneNumber, String password) async {
    try {
      final userRes = await supabase
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('password', password)
          .maybeSingle();

      if (userRes == null) {
        throw Exception('Numéro de téléphone ou mot de passe incorrect.');
      }

      // ✅ CORRIGÉ : user_model.User.fromMap
      return user_model.User.fromMap(userRes);
    } on PostgrestException catch (e) {
      throw Exception('Erreur lors de la connexion: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final session = supabase.auth.currentSession;
    return session != null;
  }

  Future<String?> getUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final userData = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return userData?['role'];
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rôle: $e');
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }
}
