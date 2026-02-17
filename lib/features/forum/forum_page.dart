import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final rows = await client.from('forum_categories').select().order('sort_order');
  return List<Map<String, dynamic>>.from(rows);
});

class ForumPage extends ConsumerWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(categoriesProvider);
    return AppScaffold(
      title: 'Fórum',
      child: data.when(
        data: (cats) => ListView(
          children: cats
              .map((c) => ListTile(
                    title: Text(c['name'] ?? ''),
                    subtitle: Text(c['description'] ?? ''),
                  ))
              .toList(),
        ),
        error: (_, __) => const Text('Erro no fórum'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
