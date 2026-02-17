import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive_console/archive_page.dart';
import '../../features/auth/onboarding_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/dossiers/dossiers_page.dart';
import '../../features/feed/feed_page.dart';
import '../../features/forum/forum_page.dart';
import '../../features/search/search_page.dart';

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
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
