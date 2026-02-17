import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../presentation/providers/app_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final inviteCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> _continueEmail() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signInWithEmail(emailCtrl.text.trim(), passCtrl.text);
      await repo.consumeInvite(inviteCtrl.text.trim());
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.appName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(AppStrings.motto),
                const SizedBox(height: 20),
                TextField(controller: inviteCtrl, decoration: const InputDecoration(labelText: 'Convite')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
                const SizedBox(height: 12),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                FilledButton(onPressed: loading ? null : _continueEmail, child: const Text('Entrar com email')),
                TextButton(
                  onPressed: loading ? null : () => ref.read(authRepositoryProvider).signInWithGoogle(),
                  child: const Text('Entrar com Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
