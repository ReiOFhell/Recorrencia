import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final globalSearchProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, q) async {
  if (q.isEmpty) return [];
  final client = ref.read(supabaseClientProvider);
  final rows = await client.rpc('search_global', params: {'query_text': q});
  return List<Map<String, dynamic>>.from(rows);
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final query = ctrl.text.trim();
    final data = ref.watch(globalSearchProvider(query));
    return AppScaffold(
      title: 'Busca',
      child: Column(
        children: [
          TextField(controller: ctrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Buscar em tudo')),
          const SizedBox(height: 16),
          Expanded(
            child: query.isEmpty
                ? const Center(child: Text('Digite algo para pesquisar em posts, tópicos e dossiês.'))
                : data.when(
                    data: (rows) => rows.isEmpty
                        ? const Center(child: Text('Nenhum resultado encontrado.'))
                        : ListView(children: rows.map((r) => ListTile(title: Text(r['title'] ?? ''), subtitle: Text(r['type'] ?? ''))).toList()),
                    error: (e, __) => Text('Erro na busca: $e'),
                    loading: () => const Center(child: CircularProgressIndicator()),
                  ),
          ),
        ],
      ),
    );
  }
}
