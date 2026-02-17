import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../presentation/providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool consent = false;

  @override
  Widget build(BuildContext context) {
    final effectsEnabled = ref.watch(effectsEnabledProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.onboardingQuote),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: consent,
              onChanged: (v) => setState(() => consent = v ?? false),
              title: const Text('Concordo com efeitos visuais raros e mensagens efêmeras do sistema.'),
            ),
            SwitchListTile(
              value: effectsEnabled,
              onChanged: reduceMotion ? null : (v) => ref.read(effectsEnabledProvider.notifier).state = v,
              title: const Text('Efeitos de Ruptura (visuais)'),
              subtitle: Text(reduceMotion ? 'Desativado por Reduzir Movimento do sistema' : 'ON/OFF'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: consent ? () => context.go('/feed') : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
