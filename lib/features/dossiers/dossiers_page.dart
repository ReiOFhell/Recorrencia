import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final dossiersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final rows = await client.from('dossiers').select().eq('guild_id', guildId).order('updated_at', ascending: false).limit(20);
  return List<Map<String, dynamic>>.from(rows);
});

class DossiersPage extends ConsumerWidget {
  const DossiersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dossiersProvider);

    return AppScaffold(
      title: 'Dossiês',
      actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => const _CreateDossierDialog()), icon: const Icon(Icons.add))],
      child: data.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nenhum dossiê encontrado.'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () => showDialog(context: context, builder: (_) => const _CreateDossierDialog()), child: const Text('Criar primeiro dossiê')),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ExpansionTile(
              title: Text(items[i]['title'] ?? ''),
              subtitle: Text('${items[i]['classification']} • ${items[i]['status']}'),
              children: [Padding(padding: const EdgeInsets.all(12), child: MarkdownBody(data: items[i]['body_md'] ?? ''))],
            ),
          );
        },
        error: (e, __) => Text('Erro em dossiês: $e'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CreateDossierDialog extends ConsumerStatefulWidget {
  const _CreateDossierDialog();

  @override
  ConsumerState<_CreateDossierDialog> createState() => _CreateDossierDialogState();
}

class _CreateDossierDialogState extends ConsumerState<_CreateDossierDialog> {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  String classification = 'open';
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final canSeal = role == 'leader';

    return AlertDialog(
      title: const Text('Novo Dossiê'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtítulo')),
            TextField(controller: bodyCtrl, minLines: 6, maxLines: 12, decoration: const InputDecoration(labelText: 'Markdown')),
            TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (vírgula)')),
            DropdownButtonFormField<String>(
              value: classification,
              items: [
                const DropdownMenuItem(value: 'open', child: Text('open')),
                const DropdownMenuItem(value: 'restricted', child: Text('restricted')),
                if (canSeal) const DropdownMenuItem(value: 'sealed', child: Text('sealed')),
              ],
              onChanged: (v) => setState(() => classification = v ?? 'open'),
            ),
            if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: loading
              ? null
              : () async {
                  final guildId = ref.read(currentGuildIdProvider);
                  final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
                  if (guildId == null || uid == null) return;
                  setState(() => loading = true);
                  try {
                    await ref.read(supabaseClientProvider).from('dossiers').insert({
                      'guild_id': guildId,
                      'author_id': uid,
                      'title': titleCtrl.text.trim(),
                      'subtitle': subtitleCtrl.text.trim(),
                      'body_md': bodyCtrl.text.trim(),
                      'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'classification': classification,
                      'status': 'published',
                    });
                    ref.invalidate(dossiersProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() => error = 'Falha ao criar dossiê: $e');
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
          child: const Text('Criar'),
        )
      ],
    );
  }
}
