import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/marker.dart';
import '../../../core/result/result.dart';

class SupabaseMarkerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MapMarker>> getMarkersForLobby(String lobbyId) async {
    try {
      final data = await _client
          .from('markers')
          .select()
          .eq('lobby_id', lobbyId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => _markerFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Result<MapMarker>> createMarker({
    required String lobbyId,
    required String createdBy,
    required String creatorNickname,
    required MarkerType type,
    required double lat,
    required double lng,
    required String text,
    MarkerVisibility visibility = MarkerVisibility.instant,
    String? imageUrl,
    int creatorLevel = 0,
    List<String> tags = const [],
  }) async {
    try {
      final data = await _client.from('markers').insert({
        'lobby_id': lobbyId,
        'created_by': createdBy,
        'creator_nickname': creatorNickname,
        'type': type.name,
        'lat': lat,
        'lng': lng,
        'text': text,
        'visibility': visibility.name,
        'image_url': imageUrl,
        'creator_level': creatorLevel,
        'tags': tags,
      }).select().single();
      return Ok(_markerFromJson(data));
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<void> deleteMarker(String markerId) async {
    await _client.from('markers').delete().eq('id', markerId);
  }

  RealtimeChannel subscribeToMarkers({
    required String lobbyId,
    required void Function(MapMarker marker) onInsert,
    required void Function(String markerId) onDelete,
  }) {
    // No server-side filter — UUID filters in Supabase Realtime Postgres
    // Changes are unreliable. Filter client-side instead.
    return _client
        .channel('markers:$lobbyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'markers',
          callback: (payload) {
            debugPrint('[Realtime] raw INSERT: ${payload.newRecord['id']} lobby=${payload.newRecord['lobby_id']}');
            final record = payload.newRecord;
            if (record['lobby_id'] != lobbyId) return;
            onInsert(_markerFromJson(record));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'markers',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String?;
            debugPrint('[Realtime] raw DELETE: $id');
            if (id != null) onDelete(id);
          },
        )
        .subscribe((status, error) {
          debugPrint('[Realtime] status=$status error=$error');
        });
  }

  MapMarker _markerFromJson(Map<String, dynamic> json) => MapMarker(
        id: json['id'] as String,
        lobbyId: json['lobby_id'] as String,
        createdBy: json['created_by'] as String,
        creatorNickname: json['creator_nickname'] as String,
        type: MarkerType.values.byName(json['type'] as String),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        text: json['text'] as String,
        imageUrl: json['image_url'] as String?,
        visibility: MarkerVisibility.values.byName(
          json['visibility'] as String? ?? 'instant',
        ),
        unlockRadiusMeters: json['unlock_radius_meters'] as int? ?? 50,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        creatorLevel: json['creator_level'] as int? ?? 0,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
      );
}
