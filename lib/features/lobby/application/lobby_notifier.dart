import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lobby.dart';
import '../infrastructure/supabase_lobby_repository.dart';
import '../../auth/application/auth_notifier.dart';
import '../../geo/application/location_notifier.dart';
import '../../xp/application/xp_notifier.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/result/result.dart';

const kCommunityLobbyId = '00000000-0000-0000-0000-000000000001';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class LobbyNotifier extends AsyncNotifier<Lobby?> {
  late final SupabaseLobbyRepository _repo;

  @override
  Future<Lobby?> build() async {
    _repo = SupabaseLobbyRepository();

    // Watch auth — if auth is still loading on startup, this notifier will
    // automatically rebuild once auth finishes (ref.read would miss that).
    final player = ref.watch(authNotifierProvider).valueOrNull;
    if (player == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final lobbyId = prefs.getString(AppConstants.prefCurrentLobbyId);
    if (lobbyId == null) return null;

    debugPrint('[Lobby] restoring lobby $lobbyId for player ${player.id}');
    final result = await _repo.joinLobby(
      lobbyId: lobbyId,
      userId: player.id,
    );
    if (result.isErr) debugPrint('[Lobby] restore failed: ${result.errorOrNull}');
    return result.valueOrNull;
  }

  Future<Result<Lobby>> createLobby({
    required String name,
    String? description,
    LobbyVisibility visibility = LobbyVisibility.public,
    int radiusKm = 30,
  }) async {
    state = const AsyncLoading();
    final player = ref.read(authNotifierProvider).valueOrNull;
    if (player == null) return const Err('Not signed in');

    final location = ref.read(locationNotifierProvider).valueOrNull;

    final result = await _repo.createLobby(
      name: name,
      description: description,
      createdBy: player.id,
      visibility: visibility,
      centerLat: location?.lat,
      centerLng: location?.lng,
      radiusKm: radiusKm,
    );

    if (result.isOk) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.prefCurrentLobbyId, result.valueOrNull!.id);
      state = AsyncData(result.valueOrNull);
      ref.read(xpNotifierProvider.notifier).addXp(xpJoinLobby);
    } else {
      state = const AsyncData(null);
    }
    return result;
  }

  Future<Result<Lobby>> joinLobby(String lobbyId) async {
    state = const AsyncLoading();
    final player = ref.read(authNotifierProvider).valueOrNull;
    if (player == null) return const Err('Not signed in');

    final result = await _repo.joinLobby(
      lobbyId: lobbyId,
      userId: player.id,
    );

    if (result.isOk) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefCurrentLobbyId, lobbyId);
      state = AsyncData(result.valueOrNull);
      ref.read(xpNotifierProvider.notifier).addXp(xpJoinLobby);
    } else {
      state = const AsyncData(null);
    }
    return result;
  }

  Future<void> leaveLobby() async {
    final player = ref.read(authNotifierProvider).valueOrNull;
    final lobby = state.valueOrNull;
    if (player != null && lobby != null) {
      await _repo.leaveLobby(lobbyId: lobby.id, userId: player.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefCurrentLobbyId);
    state = const AsyncData(null);
  }

  Future<List<Lobby>> fetchPublicLobbies() {
    return _repo.getPublicLobbies();
  }
}

final lobbyNotifierProvider = AsyncNotifierProvider<LobbyNotifier, Lobby?>(
  LobbyNotifier.new,
);

final publicLobbiesProvider = FutureProvider<List<Lobby>>((ref) async {
  ref.watch(lobbyNotifierProvider);
  final location = ref.watch(locationNotifierProvider).valueOrNull;
  final notifier = ref.read(lobbyNotifierProvider.notifier);
  final all = await notifier.fetchPublicLobbies();

  if (location == null) return all;

  return all.where((l) {
    if (l.id == kCommunityLobbyId) return true; // always visible
    if (l.centerLat == null || l.centerLng == null) return true; // legacy
    final dist =
        _haversineKm(location.lat, location.lng, l.centerLat!, l.centerLng!);
    return dist <= l.radiusKm;
  }).toList();
});
