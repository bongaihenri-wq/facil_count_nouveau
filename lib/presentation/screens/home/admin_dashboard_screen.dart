import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../profile/user_management_screen.dart';
import '../home/home_screen.dart';
import '../dashboard/dashboard_screen.dart'; 

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.people),
            tooltip: 'Gestion utilisateurs',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              color: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenue, Admin!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Administrateur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Fonctionnalités Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // 🟢 Étape 1 : On donne plus de hauteur aux cartes pour éviter l'overflow
                childAspectRatio: 0.9, 
                children: [
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Utilisateurs',
                    subtitle: 'Gérer les comptes',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    icon: Icons.lock_open,
                    title: 'Déverrouiller',
                    subtitle: 'Éléments verrouillés',
                    color: Colors.orange,
                    onTap: () {
                      // Ton action de déverrouillage ici
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.business,
                    title: 'Commerce',
                    subtitle: 'Paramètres',
                    color: Colors.green,
                    // 🟢 Étape 2 : Lien vers l'écran HomeScreen
                    onTap: () {
                      Navigator.push(
                        context,
                        // Remplace "HomeScreen" par le nom exact de ta classe d'accueil
                        MaterialPageRoute(builder: (context) => const HomeScreen()), 
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.analytics,
                    title: 'Rapports',
                    subtitle: 'Statistiques',
                    color: Colors.purple,
                    // 🟢 Étape 3 : Lien vers l'écran Tableau de bord
                    onTap: () {
                      Navigator.push(
                        context,
                        // Remplace "DashboardScreen" par le nom exact de ta classe dashboard
                        MaterialPageRoute(builder: (context) => const DashboardScreen()), 
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // 🟢 Étape 4 : Un espace invisible de 20px tout en bas de l'écran
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12), // 🟢 Réduit un peu le padding pour gagner de l'espace
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28), // 🟢 Taille légèrement réduite
              ),
              const SizedBox(height: 8),
              
              // 🟢 Flexible et texte coupé avec "..." si l'écran est vraiment trop petit
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}