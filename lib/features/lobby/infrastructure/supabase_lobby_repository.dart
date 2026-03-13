import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lobby.dart';
import '../../../core/result/result.dart';

class SupabaseLobbyRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Result<Lobby>> createLobby({
    required String name,
    required String createdBy,
    LobbyVisibility visibility = LobbyVisibility.public,
    String? description,
    double? centerLat,
    double? centerLng,
    int radiusKm = 30,
  }) async {
    try {
      final data = await _client.from('lobbies').insert({
        'name': name,
        'visibility': visibility.name,
        'created_by': createdBy,
        'description': description,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'radius_km': radiusKm,
      }).select().single();

      await _client.from('lobby_members').insert({
        'lobby_id': data['id'],
        'user_id': createdBy,
        'role': 'owner',
      });

      return Ok(_lobbyFromJson(data));
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<Result<Lobby>> joinLobby({
    required String lobbyId,
    required String userId,
  }) async {
    try {
      final data = await _client
          .from('lobbies')
          .select()
          .eq('id', lobbyId)
          .single();

      await _client.from('lobby_members').upsert(
        {
          'lobby_id': lobbyId,
          'user_id': userId,
          'role': 'member',
        },
        onConflict: 'lobby_id,user_id',
        ignoreDuplicates: true,
      );

      return Ok(_lobbyFromJson(data));
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<void> leaveLobby({
    required String lobbyId,
    required String userId,
  }) async {
    await _client
        .from('lobby_members')
        .delete()
        .eq('lobby_id', lobbyId)
        .eq('user_id', userId);
  }

  Future<List<Lobby>> getPublicLobbies() async {
    try {
      final data = await _client
          .from('lobbies')
          .select('*, lobby_members(count)')
          .eq('visibility', 'public')
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List).map((e) => _lobbyFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Lobby _lobbyFromJson(Map<String, dynamic> json) => Lobby(
        id: json['id'] as String,
        name: json['name'] as String,
        visibility: LobbyVisibility.values.byName(
          json['visibility'] as String,
        ),
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        memberCount: (json['lobby_members'] as List?)?.firstOrNull
                ?['count'] as int? ??
            1,
        description: json['description'] as String?,
        centerLat: (json['center_lat'] as num?)?.toDouble(),
        centerLng: (json['center_lng'] as num?)?.toDouble(),
        radiusKm: json['radius_km'] as int? ?? 30,
      );
}
