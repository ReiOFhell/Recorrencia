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

final appRouterProvider = Provider<GoRouter>((ref) => buildRouter(ref));

final inkosiEffectsProvider = Provider<InkosiEffectsService>((_) => InkosiEffectsService());

final reduceMotionProvider = Provider<bool>((ref) {
  return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
});

final effectsEnabledProvider = StateProvider<bool>((_) => true);
