import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/marker.dart';
import '../infrastructure/supabase_marker_repository.dart';
import '../../auth/application/auth_notifier.dart';
import '../../lobby/application/lobby_notifier.dart';
import '../../xp/application/xp_notifier.dart';
import '../../../core/result/result.dart';

class MarkerNotifier extends AsyncNotifier<List<MapMarker>> {
  late final SupabaseMarkerRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<MapMarker>> build() async {
    _repo = SupabaseMarkerRepository();
    final lobby = ref.watch(lobbyNotifierProvider).valueOrNull;
    if (lobby == null) return [];

    debugPrint('[Markers] loading for lobby ${lobby.id} (${lobby.name})');
    final markers = await _repo.getMarkersForLobby(lobby.id);
    debugPrint('[Markers] loaded ${markers.length} markers');
    _subscribeRealtime(lobby.id);

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return markers;
  }

  void _subscribeRealtime(String lobbyId) {
    _channel?.unsubscribe();
    debugPrint('[Realtime] subscribing to markers for lobby $lobbyId');
    _channel = _repo.subscribeToMarkers(
      lobbyId: lobbyId,
      onInsert: (marker) {
        debugPrint('[Realtime] INSERT marker ${marker.id} by ${marker.creatorNickname}');
        final current = state.valueOrNull ?? [];
        if (current.any((m) => m.id == marker.id)) {
          debugPrint('[Realtime] dedup — marker already in state');
          return;
        }
        state = AsyncData([marker, ...current]);
      },
      onDelete: (markerId) {
        debugPrint('[Realtime] DELETE marker $markerId');
        final current = state.valueOrNull ?? [];
        state = AsyncData(current.where((m) => m.id != markerId).toList());
      },
    );
  }

  Future<Result<MapMarker>> createMarker({
    required double lat,
    required double lng,
    required String text,
    MarkerType type = MarkerType.note,
    MarkerVisibility visibility = MarkerVisibility.instant,
    String? imageUrl,
    List<String> tags = const [],
  }) async {
    final player = ref.read(authNotifierProvider).valueOrNull;
    if (player == null) return const Err('Not signed in');

    final lobby = ref.read(lobbyNotifierProvider).valueOrNull;
    if (lobby == null) return const Err('Not in a lobby');

    final level = ref.read(playerLevelProvider).levelIndex;

    final result = await _repo.createMarker(
      lobbyId: lobby.id,
      createdBy: player.id,
      creatorNickname: player.nickname,
      type: type,
      lat: lat,
      lng: lng,
      text: text,
      visibility: visibility,
      imageUrl: imageUrl,
      creatorLevel: level,
      tags: tags,
    );

    if (result.isOk) {
      // Optimistic update
      final current = state.valueOrNull ?? [];
      state = AsyncData([result.valueOrNull!, ...current]);

      // Award XP
      final markerXp = type == MarkerType.ctaFlag ? xpCreateCta : xpCreateNote;
      ref.read(xpNotifierProvider.notifier).addXp(markerXp);
    }

    return result;
  }

  Future<void> deleteMarker(String markerId) async {
    await _repo.deleteMarker(markerId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((m) => m.id != markerId).toList());
  }
}

final markerNotifierProvider =
    AsyncNotifierProvider<MarkerNotifier, List<MapMarker>>(
  MarkerNotifier.new,
);
