import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/shared/app_scaffold.dart';

class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  Future<void> _emitInkosi(WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    final token = client.auth.currentSession?.accessToken;
    await client.functions.invoke(
      'inkosi_emit_manual',
      body: {'style': 'rupture_frame', 'intensity': 'low'},
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentRoleProvider);

    return AppScaffold(
      title: 'Arquivo',
      child: roleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Erro ao carregar perfil de acesso.'),
        data: (role) {
          final isLeader = role == 'leader';
          return ListView(
            children: [
              const ListTile(title: Text('Notificações in-app')),
              const Divider(),
              if (isLeader) ...[
                const ListTile(
                  title: Text('Console do Líder'),
                  subtitle: Text('Dashboard, usuários, convites, conteúdo e auditoria.'),
                ),
                FilledButton(onPressed: () => _emitInkosi(ref), child: const Text('Emitir Inkosi global (leader)')),
              ] else
                const ListTile(
                  title: Text('Console do Líder'),
                  subtitle: Text('Disponível apenas para membros com papel leader.'),
                ),
            ],
          );
        },
      ),
    );
  }
}
