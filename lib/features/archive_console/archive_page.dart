import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

final moderationPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final rows = await client.from('posts').select('id,body,hidden,locked,pinned,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(30);
  return List<Map<String, dynamic>>.from(rows);
});

final moderationTopicsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final rows = await client.from('forum_topics').select('id,title,hidden,locked,pinned,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(30);
  return List<Map<String, dynamic>>.from(rows);
});

final moderationDossiersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final rows = await client.from('dossiers').select('id,title,hidden,status,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(30);
  return List<Map<String, dynamic>>.from(rows);
});

final moderationCommentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final guildId = ref.read(currentGuildIdProvider);
  if (guildId == null) return [];
  final postComments = await client.from('post_comments').select('id,body,hidden,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(10);
  final topicReplies = await client.from('forum_replies').select('id,body,hidden,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(10);
  final dossierComments = await client.from('dossier_comments').select('id,body,hidden,created_at').eq('guild_id', guildId).order('created_at', ascending: false).limit(10);
  return [
    ...List<Map<String, dynamic>>.from(postComments).map((e) => {...e, '_table': 'post_comments'}),
    ...List<Map<String, dynamic>>.from(topicReplies).map((e) => {...e, '_table': 'forum_replies'}),
    ...List<Map<String, dynamic>>.from(dossierComments).map((e) => {...e, '_table': 'dossier_comments'}),
  ];
});

class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final guildId = ref.watch(currentGuildIdProvider);
    final isLeader = role == 'leader';

    return AppScaffold(
      title: 'Arquivo',
      child: ListView(
        children: [
          const ListTile(title: Text('Notificações in-app')),
          const Divider(),
          if (isLeader && guildId != null) ...[
            const ListTile(title: Text('Console do Líder')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: () => _openUsers(context, ref, guildId), child: const Text('Usuários')),
                FilledButton(onPressed: () => _openModeration(context, ref, guildId), child: const Text('Conteúdo')),
                FilledButton(onPressed: () => _emitInkosi(ref, guildId), child: const Text('Emitir Sinal Inkosi')),
                OutlinedButton(onPressed: () => _seedDefaults(ref, guildId, context), child: const Text('Inicializar Base (Seed)')),
              ],
            ),
          ] else
            const ListTile(
              title: Text('Console do Líder'),
              subtitle: Text('Disponível apenas para membros com papel leader.'),
            ),
        ],
      ),
    );
  }

  Future<void> _seedDefaults(WidgetRef ref, String guildId, BuildContext context) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    try {
      await client.functions.invoke(
        'admin_seed_defaults',
        body: {'guild_id': guildId, 'create_welcome_post': true},
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      );
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seed concluído.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha no seed: $e')));
    }
  }

  Future<void> _emitInkosi(WidgetRef ref, String guildId) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    await client.functions.invoke(
      'inkosi_emit_manual',
      body: {'guild_id': guildId, 'style': 'rupture_frame', 'intensity': 'low'},
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }

  void _openUsers(BuildContext context, WidgetRef ref, String guildId) => showDialog(context: context, builder: (_) => _UsersDialog(guildId: guildId));
  void _openModeration(BuildContext context, WidgetRef ref, String guildId) => showDialog(context: context, builder: (_) => _ModerationDialog(guildId: guildId));
}

class _UsersDialog extends ConsumerStatefulWidget {
  const _UsersDialog({required this.guildId});
  final String guildId;

  @override
  ConsumerState<_UsersDialog> createState() => _UsersDialogState();
}

class _UsersDialogState extends ConsumerState<_UsersDialog> {
  bool loading = true;
  List<Map<String, dynamic>> members = [];
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    try {
      final res = await client.functions.invoke(
        'admin_list_members',
        method: HttpMethod.get,
        queryParameters: {'guild_id': widget.guildId},
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      );
      members = List<Map<String, dynamic>>.from(res.data['members'] as List);
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setRole(String userId, String role) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    await client.functions.invoke('admin_set_member_role', body: {'guild_id': widget.guildId, 'user_id': userId, 'role': role}, headers: token == null ? null : {'Authorization': 'Bearer $token'});
    await _load();
  }

  Future<void> _setStatus(String userId, String status) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    await client.functions.invoke('admin_set_member_status', body: {'guild_id': widget.guildId, 'user_id': userId, 'status': status}, headers: token == null ? null : {'Authorization': 'Bearer $token'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Usuários da Guild'),
      content: SizedBox(
        width: 680,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Text('Erro ao listar membros: $error')
                : ListView(
                    shrinkWrap: true,
                    children: members.map((m) {
                      final profile = (m['profiles'] as Map?) ?? {};
                      final userId = m['user_id'] as String;
                      return ListTile(
                        title: Text(profile['display_name']?.toString() ?? userId),
                        subtitle: Text('role=${m['role']} • status=${m['status']}'),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (v) => _setRole(userId, v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'observer', child: Text('observer')),
                                PopupMenuItem(value: 'registrar', child: Text('registrar')),
                                PopupMenuItem(value: 'curator', child: Text('curator')),
                                PopupMenuItem(value: 'leader', child: Text('leader')),
                              ],
                              child: const Icon(Icons.shield_outlined),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) => _setStatus(userId, v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'active', child: Text('active')),
                                PopupMenuItem(value: 'suspended', child: Text('suspended')),
                                PopupMenuItem(value: 'banned', child: Text('banned')),
                              ],
                              child: const Icon(Icons.person_off_outlined),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}

class _ModerationDialog extends ConsumerWidget {
  const _ModerationDialog({required this.guildId});
  final String guildId;

  Future<void> _moderate(WidgetRef ref, String table, String id, Map<String, dynamic> patch) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    await client.functions.invoke('admin_moderate_content', body: {'guild_id': guildId, 'table': table, 'id': id, 'patch': patch}, headers: token == null ? null : {'Authorization': 'Bearer $token'});
    ref.invalidate(moderationPostsProvider);
    ref.invalidate(moderationTopicsProvider);
    ref.invalidate(moderationDossiersProvider);
    ref.invalidate(moderationCommentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(moderationPostsProvider);
    final topics = ref.watch(moderationTopicsProvider);
    final dossiers = ref.watch(moderationDossiersProvider);
    final comments = ref.watch(moderationCommentsProvider);

    Widget section(String title, AsyncValue<List<Map<String, dynamic>>> data, Widget Function(Map<String, dynamic>) tile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          data.when(
            loading: () => const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
            error: (e, __) => Text('Erro: $e'),
            data: (rows) => Column(children: rows.take(8).map(tile).toList()),
          ),
          const Divider(),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Moderação Rápida'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            children: [
              section('Posts', posts, (p) => ListTile(
                    title: Text((p['body'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('h=${p['hidden']} l=${p['locked']} p=${p['pinned']}'),
                    trailing: Wrap(spacing: 4, children: [
                      IconButton(onPressed: () => _moderate(ref, 'posts', p['id'] as String, {'hidden': !(p['hidden'] as bool)}), icon: const Icon(Icons.visibility_off_outlined)),
                      IconButton(onPressed: () => _moderate(ref, 'posts', p['id'] as String, {'locked': !(p['locked'] as bool)}), icon: const Icon(Icons.lock_outline)),
                      IconButton(onPressed: () => _moderate(ref, 'posts', p['id'] as String, {'pinned': !(p['pinned'] as bool)}), icon: const Icon(Icons.push_pin_outlined)),
                    ]),
                  )),
              section('Tópicos', topics, (t) => ListTile(
                    title: Text((t['title'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('h=${t['hidden']} l=${t['locked']} p=${t['pinned']}'),
                    trailing: Wrap(spacing: 4, children: [
                      IconButton(onPressed: () => _moderate(ref, 'forum_topics', t['id'] as String, {'hidden': !(t['hidden'] as bool)}), icon: const Icon(Icons.visibility_off_outlined)),
                      IconButton(onPressed: () => _moderate(ref, 'forum_topics', t['id'] as String, {'locked': !(t['locked'] as bool)}), icon: const Icon(Icons.lock_outline)),
                      IconButton(onPressed: () => _moderate(ref, 'forum_topics', t['id'] as String, {'pinned': !(t['pinned'] as bool)}), icon: const Icon(Icons.push_pin_outlined)),
                    ]),
                  )),
              section('Dossiês', dossiers, (d) => ListTile(
                    title: Text((d['title'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('h=${d['hidden']} status=${d['status']}'),
                    trailing: IconButton(onPressed: () => _moderate(ref, 'dossiers', d['id'] as String, {'hidden': !(d['hidden'] as bool)}), icon: const Icon(Icons.visibility_off_outlined)),
                  )),
              section('Comentários/Replies', comments, (c) => ListTile(
                    title: Text((c['body'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${c['_table']} • h=${c['hidden']}'),
                    trailing: IconButton(onPressed: () => _moderate(ref, c['_table'] as String, c['id'] as String, {'hidden': !(c['hidden'] as bool)}), icon: const Icon(Icons.visibility_off_outlined)),
                  )),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}
