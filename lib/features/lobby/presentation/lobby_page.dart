import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/lobby_notifier.dart';
import '../application/pending_join_provider.dart';
import '../../auth/application/auth_notifier.dart';
import '../../onboarding/presentation/onboarding_page.dart';
import '../../../core/result/result.dart';

const _appUrl = 'https://hoodini.vercel.app';

class LobbyPage extends ConsumerStatefulWidget {
  const LobbyPage({super.key});

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _joinCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOnboardingIfNeeded(context);
      _checkPendingJoin();
    });
  }

  Future<void> _checkPendingJoin() async {
    final pendingId = ref.read(pendingLobbyIdProvider);
    if (pendingId == null) return;
    ref.read(pendingLobbyIdProvider.notifier).state = null;
    await _joinLobby(pendingId);
  }

  Future<void> _createLobby() async {
    if (_nameController.text.trim().isEmpty) return;
    final desc = _descriptionController.text.trim();
    final result = await ref.read(lobbyNotifierProvider.notifier).createLobby(
          name: _nameController.text,
          description: desc.isEmpty ? null : desc,
        );
    if (mounted && result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorOrNull ?? 'Error')),
      );
    }
  }

  Future<void> _joinLobby(String lobbyId) async {
    if (lobbyId.isEmpty) return;
    final result =
        await ref.read(lobbyNotifierProvider.notifier).joinLobby(lobbyId);
    if (mounted && result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorOrNull ?? 'Lobby not found')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authNotifierProvider).valueOrNull;
    final publicLobbiesAsync = ref.watch(publicLobbiesProvider);
    final publicLobbies = publicLobbiesAsync.valueOrNull ?? [];
    final isLoading = ref.watch(lobbyNotifierProvider).isLoading;
    final theme = Theme.of(context);

    final communityLobby = publicLobbies
        .where((l) => l.id == kCommunityLobbyId)
        .firstOrNull;
    final nearbyLobbies =
        publicLobbies.where((l) => l.id != kCommunityLobbyId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoodini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(publicLobbiesProvider),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.person, size: 16),
              label: Text(player?.nickname ?? ''),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(publicLobbiesProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Community lobby – always at top
                  if (communityLobby != null) ...[
                    _CommunityLobbyCard(
                      lobby: communityLobby,
                      onJoin: () => _joinLobby(communityLobby.id),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Create section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create a lobby',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Lobby name',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. Offenburg Crew',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              border: OutlineInputBorder(),
                              hintText: 'What is this lobby about?',
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _createLobby(),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: isLoading ? null : _createLobby,
                            icon: const Icon(Icons.add),
                            label: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Join by ID
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join by code',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _joinCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Lobby ID',
                              border: OutlineInputBorder(),
                              hintText: 'Paste lobby ID here',
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (v) => _joinLobby(v.trim()),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () =>
                                    _joinLobby(_joinCodeController.text.trim()),
                            icon: const Icon(Icons.login),
                            label: const Text('Join'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nearby lobbies
                  if (nearbyLobbies.isNotEmpty) ...[
                    Text(
                      'Nearby lobbies',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...nearbyLobbies.map(
                      (lobby) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.people),
                          title: Text(lobby.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lobby.description != null)
                                Text(
                                  lobby.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              Text('${lobby.memberCount} members'),
                            ],
                          ),
                          isThreeLine: lobby.description != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                tooltip: 'Copy invite link',
                                onPressed: () => _copyInviteLink(
                                    context, lobby.id, lobby.name),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () => _joinLobby(lobby.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityLobbyCard extends StatelessWidget {
  const _CommunityLobbyCard({required this.lobby, required this.onJoin});
  final dynamic lobby;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF1A0000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCC0000), width: 1.5),
      ),
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lobby.name as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF4444),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCC0000)),
                    ),
                    child: const Text(
                      'COMMUNITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFFFF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (lobby.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  lobby.description as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.public,
                      size: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    'Weltweit sichtbar · ${lobby.memberCount} Mitglieder',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _copyInviteLink(BuildContext context, String lobbyId, String lobbyName) {
  final link = '$_appUrl/join/$lobbyId';
  Clipboard.setData(ClipboardData(text: link));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Invite link copied for "$lobbyName"'),
      action: SnackBarAction(label: 'OK', onPressed: () {}),
    ),
  );
}
