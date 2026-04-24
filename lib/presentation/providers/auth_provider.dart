import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/subscription_model.dart';

/// --- ÉTAT DE L'AUTHENTIFICATION ---
/// Gère l'utilisateur actuel, le chargement et les erreurs
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

  // Getters utiles pour l'UI
  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  String? get businessId => currentUser?.businessId;

  // Logique d'accès SaaS : l'utilisateur peut-il utiliser les fonctions Pro ?
  bool get canAccessApp => currentUser?.canAccessProFeatures ?? false;
  SubscriptionType get currentPlan => currentUser?.subscription?.type ?? SubscriptionType.trial;
}

/// --- PROVIDER GLOBAL ---
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// --- NOTIFIER D'AUTHENTIFICATION ---
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState());

  /// 🟢 INITIALISATION
  /// Vérifie si un token existe et récupère le profil utilisateur au démarrage
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await SecureStorageService.getToken();
      if (token != null) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(currentUser: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      await SecureStorageService.clearAll();
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// 🟢 CONNEXION
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

  /// 🟢 RAFRAÎCHISSEMENT DU STATUT (Indispensable pour débloquer l'accès)
  Future<void> refreshSubscriptionStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.getCurrentUser(); 
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// 🟢 INSCRIPTION (Compte Administrateur + Entreprise)
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

  /// 🟢 CRÉATION D'EMPLOYÉ (Réservé à l'Admin)
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

  /// 🟢 RÉCUPÉRATION DES UTILISATEURS DU BUSINESS
  Future<List<UserModel>> getBusinessUsers() async {
    if (state.currentUser == null || !state.currentUser!.isAdmin) return [];
    try {
      return await _authService.getBusinessUsers(state.currentUser!.businessId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// 🟢 ACTIVER / DÉSACTIVER UN UTILISATEUR
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    if (state.currentUser == null || !state.currentUser!.isAdmin) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.toggleUserStatus(userId, isActive);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// 🟢 MISE À JOUR DU PROFIL
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

  /// 🟢 DÉCONNEXION
  Future<void> logout() async {
    await _authService.logout();
    await SecureStorageService.clearAll();
    state = AuthState(); // Reset l'état de l'application
  }

  /// 🟢 NETTOYAGE DES ERREURS
  void clearError() => state = state.copyWith(error: null);
}
