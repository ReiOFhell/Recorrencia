import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final rows = await client.from('forum_categories').select().eq('guild_id', guildId).order('sort_order');
  return List<Map<String, dynamic>>.from(rows);
});

class ForumPage extends ConsumerWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(categoriesProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreateTopic = ['registrar', 'curator', 'leader'].contains(role);
    final canManageCategories = ['curator', 'leader'].contains(role);

    return AppScaffold(
      title: 'Fórum',
      actions: [
        if (canManageCategories)
          IconButton(
            onPressed: () => showDialog(context: context, builder: (_) => const _ManageCategoriesDialog()),
            icon: const Icon(Icons.settings),
            tooltip: 'Gerenciar Categorias',
          ),
        if (canCreateTopic)
          IconButton(
            onPressed: () => showDialog(context: context, builder: (_) => const _CreateTopicDialog()),
            icon: const Icon(Icons.add),
            tooltip: 'Novo Tópico',
          ),
      ],
      child: data.when(
        data: (cats) {
          if (cats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nenhuma categoria disponível.'),
                  const SizedBox(height: 8),
                  if (canManageCategories)
                    FilledButton(
                      onPressed: () => showDialog(context: context, builder: (_) => const _ManageCategoriesDialog()),
                      child: const Text('Criar primeira categoria'),
                    ),
                ],
              ),
            );
          }
          return ListView(
            children: cats
                .map((c) => ListTile(
                      title: Text(c['name'] ?? ''),
                      subtitle: Text(c['description'] ?? ''),
                      trailing: Text('min: ${c['min_role']}'),
                    ))
                .toList(),
          );
        },
        error: (e, __) => Text('Erro no fórum: $e'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CreateTopicDialog extends ConsumerStatefulWidget {
  const _CreateTopicDialog();

  @override
  ConsumerState<_CreateTopicDialog> createState() => _CreateTopicDialogState();
}

class _CreateTopicDialogState extends ConsumerState<_CreateTopicDialog> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  String? categoryId;
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    final guildId = ref.read(currentGuildIdProvider);
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (guildId == null || uid == null || categoryId == null) return;

    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(supabaseClientProvider).from('forum_topics').insert({
        'guild_id': guildId,
        'category_id': categoryId,
        'author_id': uid,
        'title': titleCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
        'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = 'Falha ao criar tópico: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return AlertDialog(
      title: const Text('Novo Tópico'),
      content: categoriesAsync.when(
        data: (categories) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categoryId,
                hint: const Text('Categoria'),
                items: categories
                    .map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['name'] as String)))
                    .toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
              TextField(controller: bodyCtrl, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Conteúdo')),
              TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags')), 
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        error: (e, __) => Text('Erro ao carregar categorias: $e'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: loading ? null : _submit, child: const Text('Criar')),
      ],
    );
  }
}

class _ManageCategoriesDialog extends ConsumerStatefulWidget {
  const _ManageCategoriesDialog();

  @override
  ConsumerState<_ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends ConsumerState<_ManageCategoriesDialog> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  int sortOrder = 10;
  String minRole = 'observer';

  Future<void> _create() async {
    final guildId = ref.read(currentGuildIdProvider);
    if (guildId == null) return;
    await ref.read(supabaseClientProvider).from('forum_categories').insert({
      'guild_id': guildId,
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'sort_order': sortOrder,
      'min_role': minRole,
    });
    ref.invalidate(categoriesProvider);
    if (mounted) {
      nameCtrl.clear();
      descCtrl.clear();
    }
  }

  Future<void> _softDelete(String id) async {
    await ref.read(supabaseClientProvider).from('forum_categories').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return AlertDialog(
      title: const Text('Gerenciar Categorias'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
            DropdownButtonFormField<String>(
              value: minRole,
              items: const [
                DropdownMenuItem(value: 'observer', child: Text('observer')),
                DropdownMenuItem(value: 'registrar', child: Text('registrar')),
                DropdownMenuItem(value: 'curator', child: Text('curator')),
                DropdownMenuItem(value: 'leader', child: Text('leader')),
              ],
              onChanged: (v) => setState(() => minRole = v ?? 'observer'),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _create, child: const Text('Adicionar categoria')),
            const Divider(),
            Flexible(
              child: categoriesAsync.when(
                data: (items) => ListView(
                  shrinkWrap: true,
                  children: items
                      .map((c) => ListTile(
                            title: Text(c['name'] ?? ''),
                            subtitle: Text(c['description'] ?? ''),
                            trailing: IconButton(onPressed: () => _softDelete(c['id'] as String), icon: const Icon(Icons.delete_outline)),
                          ))
                      .toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Erro: $e'),
              ),
            )
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}
