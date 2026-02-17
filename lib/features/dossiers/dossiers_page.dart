import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final dossiersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final rows = await client.from('dossiers').select().order('updated_at', ascending: false).limit(20);
  return List<Map<String, dynamic>>.from(rows);
});

class DossiersPage extends ConsumerWidget {
  const DossiersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dossiersProvider);
    return AppScaffold(
      title: 'Dossiês',
      child: data.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => ExpansionTile(
            title: Text(items[i]['title'] ?? ''),
            subtitle: Text('${items[i]['classification']} • ${items[i]['status']}'),
            children: [MarkdownBody(data: items[i]['body_md'] ?? '')],
          ),
        ),
        error: (_, __) => const Text('Erro em dossiês'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
