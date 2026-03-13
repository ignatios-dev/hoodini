import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_notifier.dart';
import '../features/auth/presentation/nickname_page.dart';
import '../features/lobby/application/lobby_notifier.dart';
import '../features/lobby/application/pending_join_provider.dart';
import '../features/lobby/presentation/lobby_page.dart';
import '../features/map/presentation/map_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/nickname',
        builder: (ctx, state) => const NicknamePage(),
      ),
      GoRoute(
        path: '/lobby',
        builder: (ctx, state) => const LobbyPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (ctx, state) => const MapPage(),
      ),
      GoRoute(
        path: '/join/:lobbyId',
        builder: (ctx, state) {
          final lobbyId = state.pathParameters['lobbyId']!;
          return _JoinRedirectPage(lobbyId: lobbyId);
        },
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (prev, next) => notifyListeners());
    _ref.listen(lobbyNotifierProvider, (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final lobbyState = _ref.read(lobbyNotifierProvider);

    if (authState.isLoading || lobbyState.isLoading) return null;

    final player = authState.valueOrNull;
    final lobby = lobbyState.valueOrNull;
    final path = state.matchedLocation;

    if (path.startsWith('/join/')) return null;

    if (player == null) {
      return path == '/nickname' ? null : '/nickname';
    }
    if (lobby == null) {
      return path == '/lobby' ? null : '/lobby';
    }
    return path == '/map' ? null : '/map';
  }
}

class _JoinRedirectPage extends ConsumerWidget {
  const _JoinRedirectPage({required this.lobbyId});
  final String lobbyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingLobbyIdProvider.notifier).state = lobbyId;
      final player = ref.read(authNotifierProvider).valueOrNull;
      context.go(player == null ? '/nickname' : '/lobby');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
