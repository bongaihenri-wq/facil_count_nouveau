import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

/// 🏪 Nom de la boutique active (se met à jour automatiquement au switch)
final currentBusinessProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final bId = ref.watch(authProvider).businessId;
  if (bId == null) return null;
  final data = await Supabase.instance.client
      .from('businesses')
      .select('id, name, code')
      .eq('id', bId)
      .maybeSingle();
  return data;
});

/// Badge affiché en haut des écrans pour situer l'utilisateur
class BusinessNameBadge extends ConsumerWidget {
  const BusinessNameBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(currentBusinessProvider);
    return biz.when(
      data: (b) => b == null
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${b['name']} • ${b['code'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}