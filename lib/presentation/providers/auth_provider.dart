import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/models/user_model.dart';

// Provider global
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;

  AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  String? get businessId => currentUser?.businessId;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState());

  // Initialisation - vérifie si déjà connecté
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(currentUser: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
    print('🔍 Initialisation auth...');
    print('🔍 Token existant: ${await SecureStorageService.getToken()}');
  }

  // Login
  Future<bool> login(String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(phoneNumber, password);
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
    
  }

  // Register
  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String businessName,
    required String businessType,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.registerUser(
        phoneNumber: phoneNumber,
        password: password,
        businessName: businessName,
        businessType: businessType,
        firstName: firstName,
        lastName: lastName,
        email: email,
        isAdmin: true,
      );
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (state.currentUser == null) return false;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final updated = await _authService.updateUser(state.currentUser!.id, data);
      state = state.copyWith(currentUser: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // ========== MÉTHODES MANQUANTES POUR USER MANAGEMENT ==========

  // Récupérer tous les utilisateurs du business (admin only)
  Future<List<UserModel>> getBusinessUsers() async {
    if (state.currentUser == null || !state.currentUser!.isAdmin) {
      return [];
    }

    try {
      return await _authService.getBusinessUsers(state.currentUser!.businessId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Créer un nouvel utilisateur (admin only)
  Future<bool> createUser({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
    String role = 'user',
  }) async {
    if (state.currentUser == null || !state.currentUser!.isAdmin) {
      state = state.copyWith(error: 'Accès réservé aux administrateurs');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.createUser(
        phoneNumber: phoneNumber,
        password: password,
        businessId: state.currentUser!.businessId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // Activer/désactiver un utilisateur (admin only)
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    if (state.currentUser == null || !state.currentUser!.isAdmin) {
      return false;
    }

    try {
      await _authService.toggleUserStatus(userId, isActive);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}