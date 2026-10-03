import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/business_repository.dart';
import '../providers/auth_provider.dart';
import 'add_business_sheet.dart';

/// 🔄 Sélecteur de boutique (en haut du dashboard)
class BusinessSwitcher extends ConsumerStatefulWidget {
  const BusinessSwitcher({super.key});

  @override
  ConsumerState<BusinessSwitcher> createState() => _BusinessSwitcherState();
}

class _BusinessSwitcherState extends ConsumerState<BusinessSwitcher> {
  List<Map<String, dynamic>> _businesses = [];
  String? _currentId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await BusinessRepository().getMyBusinesses();
      // 🆕 Filtre les liaisons orphelines (business null)
      final valid = list.where((row) => row['businesses'] != null).toList();
      if (mounted) {
        final activeId = ref.read(authProvider).businessId;
        final ids = valid
            .map((r) => (r['businesses'] as Map)['id'] as String)
            .toList();
        setState(() {
          _businesses = valid;
          // 🆕 _currentId doit TOUJOURS être dans la liste (sinon DropdownButton plante)
          _currentId = ids.contains(activeId)
              ? activeId
              : (ids.isNotEmpty ? ids.first : null);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

    Future<void> _switch(String id) async {
    if (id == _currentId) return;
    setState(() => _currentId = id);
    await BusinessRepository().switchBusiness(id);
    await ref.read(authProvider.notifier).refreshSubscriptionStatus();
    // 🆕 Recharge l'app depuis la racine (tous les écrans refetch en initState)
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _businesses.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(children: [
        const Icon(Icons.storefront, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentId,
              isExpanded: true,
              hint: const Text('Choisir une boutique'),
              items: _businesses.map((row) {
                final biz = row['businesses'] as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: biz['id'] as String,
                  child: Text(
                    '${biz['name']} (${biz['code'] ?? ''})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => v != null ? _switch(v) : null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_business, color: Colors.green),
          tooltip: 'Ajouter une boutique',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddBusinessSheet(),
          ).then((_) => _load()),
        ),
      ]),
    );
  }
}