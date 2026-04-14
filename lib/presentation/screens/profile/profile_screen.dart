import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/role_badge.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(authProvider.notifier).updateProfile({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.isEmpty ? null : _emailController.text.trim(),
    });

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            )
          else
            IconButton(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                : const Icon(Icons.check),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar & Role
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.initial,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RoleBadge(role: user.role),
                  const SizedBox(height: 8),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- NOUVEAU : CARTE DE STATUT D'ABONNEMENT ---
            _buildSubscriptionCard(user),
            
            const SizedBox(height: 16),
            
            // Info Cards
            _buildInfoCard(
              title: 'Informations personnelles',
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  icon: Icons.person,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoCard(
              title: 'Informations du compte',
              children: [
                _buildTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.business, color: AppColors.primary),
                  title: const Text('ID Commerce'),
                  subtitle: Text(
                    user.businessId,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text('Membre depuis'),
                  subtitle: Text(
                    '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget interne pour la gestion de l'abonnement
  Widget _buildSubscriptionCard(user) {
    // Utilisation des getters du modèle pour éviter les erreurs de calcul
    final remainingDays = user.trialDaysRemaining;
    final progress = user.trialProgress;
    final isExpired = user.isTrialExpired;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Statut de l'abonnement",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(isExpired),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isExpired 
                ? "Votre période d'essai est terminée" 
                : "Il vous reste $remainingDays jours d'essai gratuit",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpired ? Colors.red : (remainingDays < 7 ? Colors.orange : AppColors.primary),
                ),
              ),
            ),
            if (isExpired) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logique de paiement future
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Passer à la version Pro"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExpired ? Colors.red : Colors.blue),
      ),
      child: Text(
        isExpired ? "EXPIRÉ" : "ESSAI",
        style: TextStyle(
          color: isExpired ? Colors.red : Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? AppColors.primary : Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
    );
  }
}
