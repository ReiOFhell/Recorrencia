import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final feedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('posts').select().order('created_at', ascending: false).limit(30);
  return List<Map<String, dynamic>>.from(res);
});

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(feedProvider);
    return AppScaffold(
      title: 'Feed',
      child: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => Card(child: ListTile(title: Text(items[i]['body'] ?? ''), subtitle: Text(items[i]['visibility'] ?? 'public'))),
        ),
        error: (_, __) => const Text('Erro ao carregar feed'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
