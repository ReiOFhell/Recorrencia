import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_providers.dart';

class EnsureMembershipPage extends ConsumerStatefulWidget {
  const EnsureMembershipPage({super.key});

  @override
  ConsumerState<EnsureMembershipPage> createState() => _EnsureMembershipPageState();
}

class _EnsureMembershipPageState extends ConsumerState<EnsureMembershipPage> {
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureMembership);
  }

  Future<void> _ensureMembership() async {
    try {
      final result = await ref.read(authRepositoryProvider).ensureMembership();
      ref.read(membershipDataProvider.notifier).state = Map<String, dynamic>.from(result['membership'] as Map);
      ref.read(membershipReadyProvider.notifier).state = true;
      if (mounted) context.go('/feed');
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Falha ao preparar acesso: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Preparando seu acesso...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _ensureMembership, child: const Text('Tentar novamente')),
                ],
              ),
      ),
    );
  }
}
