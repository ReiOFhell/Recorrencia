import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_router.dart';
import '../../core/services/inkosi_effects_service.dart';
import '../../data/repositories_impl/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(supabaseClientProvider));
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseClientProvider).auth.onAuthStateChange;
});

final membershipReadyProvider = StateProvider<bool>((_) => false);
final membershipDataProvider = StateProvider<Map<String, dynamic>?>((_) => null);

final currentRoleProvider = Provider<String?>((ref) {
  final membership = ref.watch(membershipDataProvider);
  return membership?['role'] as String?;
});

final currentGuildIdProvider = Provider<String?>((ref) {
  final membership = ref.watch(membershipDataProvider);
  return membership?['guild_id'] as String?;
});

final appRouterProvider = Provider<GoRouter>((ref) => buildRouter(ref));

final inkosiEffectsProvider = Provider<InkosiEffectsService>((_) => InkosiEffectsService());

final reduceMotionProvider = Provider<bool>((ref) {
  return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
});

final effectsEnabledProvider = StateProvider<bool>((_) => true);
