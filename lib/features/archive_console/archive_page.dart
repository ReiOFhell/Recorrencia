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
    return AppScaffold(
      title: 'Arquivo',
      child: ListView(
        children: [
          const ListTile(title: Text('Notificações in-app')),
          const Divider(),
          const ListTile(title: Text('Console do Líder'), subtitle: Text('Dashboard, usuários, convites, conteúdo e auditoria.')),
          FilledButton(onPressed: () => _emitInkosi(ref), child: const Text('Emitir Inkosi global (leader)')),
        ],
      ),
    );
  }
}
