import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/services/user_service.dart';
import 'package:facil_count_nouveau/data/models/user_model.dart' as user_model;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _userService = UserService();
  List<user_model.User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Remplacez par l'ID du commerce de l'admin
      final users = await _userService.getUsersByBusiness('business_id');
      setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord Admin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user.phoneNumber),
                  subtitle: Text(user.role),
                  trailing: IconButton(
                    icon: Icon(
                      user.isActive ? Icons.lock_open : Icons.lock,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    onPressed: () async {
                      final locked = !user.isActive;
                      await _userService.lockUser(user.id, locked);
                      _loadUsers();
                    },
                  ),
                );
              },
            ),
    );
  }
}
