import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/business_model.dart';
import 'secure_storage_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Hash password
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool _verifyPassword(String password, String hashed) {
    return BCrypt.checkpw(password, hashed);
  }

  // Login
  Future<UserModel> login(String phoneNumber, String password) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('phone_number', phoneNumber)
          .eq('is_active', true)
          .single();

      final user = UserModel.fromJson(response);

      if (!_verifyPassword(password, user.password)) {
        throw Exception('Mot de passe incorrect');
      }

      // Store session
      await SecureStorageService.setUserId(user.id);
      await SecureStorageService.setRole(user.role);
      // await SecureStorageService.setBusinessId(user.businessId);  // Supprimé
      await SecureStorageService.setToken('session_${user.id}_${DateTime.now().millisecondsSinceEpoch}');

      return user;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Register - Creates business + admin user
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
      // 1. Create Business
      final businessResponse = await _supabase
          .from('businesses')
          .insert({
            'name': businessName,
            'type': businessType,
            'city': '',
            'country': "Côte d'Ivoire",
          })
          .select()
          .single();

      final business = BusinessModel.fromJson(businessResponse);

      // 2. Create Admin User
      final hashedPassword = _hashPassword(password);
      
      final userResponse = await _supabase
          .from('users')
          .insert({
            'phone_number': phoneNumber,
            'password': hashedPassword,
            'business_id': business.id,
            'role': isAdmin ? 'admin' : 'user',
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'is_active': true,
          })
          .select()
          .single();

      final user = UserModel.fromJson(userResponse);

      // 3. Store session
      await SecureStorageService.setUserId(user.id);
      await SecureStorageService.setRole(user.role);
      // await SecureStorageService.setBusinessId(user.businessId);  // Supprimé
      await SecureStorageService.setToken('session_${user.id}_${DateTime.now().millisecondsSinceEpoch}');

      return user;
    } catch (e) {
      throw Exception("Erreur d'inscription: $e");
    }
  }

  // Get current user from storage
  Future<UserModel?> getCurrentUser() async {
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

  // Nouvelle méthode pour récupérer le business_id
  Future<String?> getCurrentBusinessId() async {
    final user = await getCurrentUser();
    return user?.businessId;
  }

  // Update user
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

  // Create additional user
  Future<UserModel> createUser({
    required String phoneNumber,
    required String password,
    required String businessId,
    required String firstName,
    required String lastName,
    String? email,
    String role = 'user',
  }) async {
    try {
      final hashedPassword = _hashPassword(password);
      
      final response = await _supabase
          .from('users')
          .insert({
            'phone_number': phoneNumber,
            'password': hashedPassword,
            'business_id': businessId,
            'role': role,
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'is_active': true,
          })
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception("Erreur création utilisateur: $e");
    }
  }

  // Get users by business
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

  // Toggle user active status
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

  // Logout
  Future<void> logout() async {
    await SecureStorageService.clearAll();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.getToken();
    return token != null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await SecureStorageService.getRole();
  }

  Future<String?> getCurrentUserId() async {
    return await SecureStorageService.getUserId();
  }
}