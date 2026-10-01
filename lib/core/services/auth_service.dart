import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/business_model.dart';
import 'secure_storage_service.dart';
import '../constants/app_config.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== HELPERS ====================

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool _verifyPassword(String password, String hashed) {
    return BCrypt.checkpw(password, hashed);
  }

  /// Convertit un téléphone en email synthétique (JWT)
  static String phoneToEmail(String phone) =>
      '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@phone.facilcount.app';

  // ==================== LOGIN ====================

    Future<UserModel> login(String phoneNumber, String password) async {
    try {
      // 🔐 Login JWT unifié — tout le monde passe par Supabase Auth
      // (mot de passe vérifié côté SERVEUR, jamais dans le code)
      final res = await _supabase.auth.signInWithPassword(
        email: phoneToEmail(phoneNumber),
        password: password,
      );
      if (res.user == null) throw Exception('Échec de la connexion');

      final data = await _supabase
          .from('users')
          .select('*')
          .eq('id', res.user!.id)
          .eq('is_active', true)
          .single();

      final user = UserModel.fromJson(data);

      await SecureStorageService.setUserId(user.id);
      await SecureStorageService.setRole(user.role);
      await SecureStorageService.setToken(
          res.session?.accessToken ?? 'jwt_session');
      return user;
    } on AuthException catch (e) {
      await SecureStorageService.clearAll();
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('not found') ||
          msg.contains('credentials') || msg.contains('confirmed')) {
        throw Exception('Numéro ou mot de passe incorrect');
      }
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      await SecureStorageService.clearAll();
      throw Exception('Erreur de connexion: $e');
    }
  }
  // ==================== INSCRIPTION (inchangée) ====================

   Future<UserModel> registerUser({
    required String phoneNumber,
    required String password,
    required String businessName,
    required String businessType,
    required String firstName,
    required String lastName,
    String? email,
    bool isAdmin = true,
  }) async {
    try {
      final res = await _supabase.functions.invoke('register-business', body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'businessName': businessName,
        'businessType': businessType,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });

      if (res.status != 200) {
        throw Exception(res.data['error'] ?? "Erreur d'inscription");
      }

      // 🆕 Connexion automatique (le compte auth vient d'être créé)
      return await login(phoneNumber, password);
    } catch (e) {
      throw Exception(
          "Erreur d'inscription: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  // ==================== SESSION ====================

  Future<UserModel?> getCurrentUser() async {
    // 🆕 Session Supabase d'abord
    final authUser = _supabase.auth.currentUser;
    if (authUser != null) {
      try {
        final data = await _supabase
            .from('users')
            .select('*')
            .eq('id', authUser.id)
            .single();
        return UserModel.fromJson(data);
      } catch (_) {}
    }
    // Fallback legacy
    final userId = await SecureStorageService.getUserId();
    if (userId == null) return null;
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<String?> getCurrentBusinessId() async {
    final user = await getCurrentUser();
    return user?.businessId;
  }

  Future<String?> getCurrentUserId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser != null) return authUser.id;
    return await SecureStorageService.getUserId();
  }

  Future<bool> isLoggedIn() async {
    if (_supabase.auth.currentUser != null) return true;
    final token = await SecureStorageService.getToken();
    return token != null;
  }

  Future<String?> getUserRole() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser != null) {
      final roleClaim = authUser.userMetadata?['role'];
      if (roleClaim is String) return roleClaim;
    }
    return await SecureStorageService.getRole();
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    await SecureStorageService.clearAll();
  }

  // ==================== GESTION USERS (inchangée) ====================

  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('password') && data['password'] != null) {
        data['password'] = _hashPassword(data['password']);
      }

      final response = await _supabase
          .from('users')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur mise à jour: $e');
    }
  }

    Future<UserModel> createUser({
    required String phoneNumber,
    required String password,
    required String businessId,
    required String firstName,
    required String lastName,
    String? email,
    String role = 'user',
  }) async {
    final res = await _supabase.functions.invoke('admin-create-user', body: {
      'phoneNumber': phoneNumber,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
    });

    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Erreur création utilisateur');
    }

    final data = await _supabase
        .from('users')
        .select('*')
        .eq('phone_number', phoneNumber)
        .single();
    return UserModel.fromJson(data);
  }

  Future<List<UserModel>> getBusinessUsers(String businessId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur récupération utilisateurs: $e');
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erreur changement statut: $e');
    }
  }

  // ==================== MOT DE PASSE ====================

  Future<void> updatePasswordByPhone(String phoneNumber, String newPassword) async {
    final hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await _supabase
        .from('users')
        .update({
          'password': hashed,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('phone_number', phoneNumber);
  }

  Future<void> changePassword(String phoneNumber, String newPassword) async {
    // 1. Met à jour côté Supabase Auth (si session Supabase active)
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (_) {}
    // 2. Sync public.users + retire le flag
    final hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await _supabase
        .from('users')
        .update({
          'password': hashed,
          'must_change_password': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('phone_number', phoneNumber);
  }
}