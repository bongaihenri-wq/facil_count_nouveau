import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import 'secure_storage_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== HELPERS ====================

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// 🆕 Normalise : enlève l'indicatif 225 si présent (0749635522 == +2250749635522)
  static String _canonicalPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 10 && d.startsWith('225')) return d.substring(3);
    return d;
  }

  /// Convertit un téléphone en email synthétique (format canonique)
  static String phoneToEmail(String phone) =>
      '${_canonicalPhone(phone)}@phone.facilcount.app';

  // ==================== LOGIN ====================

  Future<UserModel> login(String phoneNumber, String password) async {
    try {
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
      if (msg.contains('invalid') ||
          msg.contains('not found') ||
          msg.contains('credentials') ||
          msg.contains('confirmed')) {
        throw Exception('Numéro ou mot de passe incorrect');
      }
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      await SecureStorageService.clearAll();
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ==================== INSCRIPTION (Edge Function) ====================

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

      return await login(phoneNumber, password);
    } catch (e) {
      throw Exception(
          "Erreur d'inscription: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  // ==================== SESSION ====================

  Future<UserModel?> getCurrentUser() async {
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
    final userId = await SecureStorageService.getUserId();
    if (userId == null) return null;
    try {
      final response =
          await _supabase.from('users').select('*').eq('id', userId).single();
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

  // ==================== GESTION USERS ====================

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
    try {
      await _supabase.auth
          .updateUser(UserAttributes(password: newPassword));
    } catch (_) {}
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