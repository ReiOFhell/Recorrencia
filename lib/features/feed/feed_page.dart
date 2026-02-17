import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final feedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final res = await client
      .from('posts')
      .select()
      .eq('guild_id', guildId)
      .order('pinned', ascending: false)
      .order('created_at', ascending: false)
      .limit(30);
  return List<Map<String, dynamic>>.from(res);
});

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(feedProvider);

    return AppScaffold(
      title: 'Feed',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => showDialog(context: context, builder: (_) => const _CreatePostDialog()),
        ),
      ],
      child: data.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ainda não há posts.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => showDialog(context: context, builder: (_) => const _CreatePostDialog()),
                    child: const Text('Crie o primeiro post'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final tags = (item['tags'] as List?)?.cast<String>() ?? const <String>[];
              return Card(
                child: ListTile(
                  title: Text(item['body'] ?? ''),
                  subtitle: Text('${item['visibility'] ?? 'public'} • ${tags.join(', ')}'),
                  trailing: item['pinned'] == true ? const Icon(Icons.push_pin) : null,
                ),
              );
            },
          );
        },
        error: (e, __) => Text('Erro ao carregar feed: $e'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CreatePostDialog extends ConsumerStatefulWidget {
  const _CreatePostDialog();

  @override
  ConsumerState<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<_CreatePostDialog> {
  final bodyCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  bool restricted = false;
  String minRole = 'registrar';
  bool loading = false;
  String? error;
  PlatformFile? pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() => pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    final guildId = ref.read(currentGuildIdProvider);
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;

    if (guildId == null || uid == null) {
      setState(() => error = 'Sessão inválida.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final post = await client
          .from('posts')
          .insert({
            'guild_id': guildId,
            'author_id': uid,
            'body': bodyCtrl.text.trim(),
            'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            'visibility': restricted ? 'restricted' : 'public',
            'min_role': restricted ? minRole : null,
          })
          .select()
          .single();

      if (pickedFile?.bytes != null) {
        final bytes = pickedFile!.bytes as Uint8List;
        final path = '$guildId/posts/${post['id']}/${pickedFile!.name}';
        await client.storage.from('attachments').uploadBinary(path, bytes);
        await client.from('attachments').insert({
          'guild_id': guildId,
          'owner_id': uid,
          'bucket': 'attachments',
          'path': path,
          'mime': pickedFile!.extension == 'pdf' ? 'application/pdf' : 'image/*',
          'size_bytes': pickedFile!.size,
          'target_type': 'post',
          'target_id': post['id'],
        });
      }

      ref.invalidate(feedProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => error = 'Falha ao criar post: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bodyCtrl, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Texto')),
            TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (separadas por vírgula)')),
            SwitchListTile(
              value: restricted,
              onChanged: (v) => setState(() => restricted = v),
              title: const Text('Restrito por role'),
            ),
            if (restricted)
              DropdownButtonFormField<String>(
                value: minRole,
                items: const [
                  DropdownMenuItem(value: 'registrar', child: Text('registrar')),
                  DropdownMenuItem(value: 'curator', child: Text('curator')),
                  DropdownMenuItem(value: 'leader', child: Text('leader')),
                ],
                onChanged: (v) => setState(() => minRole = v ?? 'registrar'),
              ),
            TextButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file), label: Text(pickedFile?.name ?? 'Anexo imagem/pdf (opcional)')),
            if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: loading ? null : _submit, child: loading ? const CircularProgressIndicator() : const Text('Publicar')),
      ],
    );
  }
}
