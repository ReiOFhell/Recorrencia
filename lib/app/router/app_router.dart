import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_providers.dart';
import '../../features/archive_console/archive_page.dart';
import '../../features/auth/ensure_membership_page.dart';
import '../../features/auth/onboarding_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/dossiers/dossiers_page.dart';
import '../../features/feed/feed_page.dart';
import '../../features/forum/forum_page.dart';
import '../../features/search/search_page.dart';

GoRouter buildRouter(Ref ref) {
  final refresh = GoRouterRefreshStream(ref.read(authStateChangesProvider.stream));
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) {
      final client = ref.read(supabaseClientProvider);
      final isAuthenticated = client.auth.currentSession != null;
      final isMembershipReady = ref.read(membershipReadyProvider);
      final path = state.matchedLocation;

      if (!isAuthenticated) {
        ref.read(membershipReadyProvider.notifier).state = false;
        ref.read(membershipDataProvider.notifier).state = null;
        if (path == '/onboarding' || path == '/sign-in') return null;
        return '/onboarding';
      }

      if (!isMembershipReady && path != '/ensure-membership') {
        return '/ensure-membership';
      }

      if (isMembershipReady && (path == '/sign-in' || path == '/onboarding' || path == '/ensure-membership')) {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/ensure-membership', builder: (_, __) => const EnsureMembershipPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => MainShell(navShell: navShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/feed', builder: (_, __) => const FeedPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/forum', builder: (_, __) => const ForumPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/dossiers', builder: (_, __) => const DossiersPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (_, __) => const SearchPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/archive', builder: (_, __) => const ArchivePage())]),
        ],
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navShell});

  final StatefulNavigationShell navShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navShell.currentIndex,
        onDestinationSelected: navShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Fórum'),
          NavigationDestination(icon: Icon(Icons.folder_open_outlined), label: 'Dossiês'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Busca'),
          NavigationDestination(icon: Icon(Icons.archive_outlined), label: 'Arquivo'),
        ],
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
