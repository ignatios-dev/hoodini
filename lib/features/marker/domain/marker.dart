enum MarkerType { note, photo, ctaFlag }

enum MarkerVisibility { instant, proximityUnlock }

class MapMarker {
  const MapMarker({
    required this.id,
    required this.lobbyId,
    required this.createdBy,
    required this.creatorNickname,
    required this.type,
    required this.lat,
    required this.lng,
    required this.text,
    this.imageUrl,
    this.visibility = MarkerVisibility.instant,
    this.unlockRadiusMeters = 50,
    this.expiresAt,
    required this.createdAt,
    this.creatorLevel = 0,
    this.tags = const [],
  });

  final String id;
  final String lobbyId;
  final String createdBy;
  final String creatorNickname;
  final MarkerType type;
  final double lat;
  final double lng;
  final String text;
  final String? imageUrl;
  final MarkerVisibility visibility;
  final int unlockRadiusMeters;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int creatorLevel;
  final List<String> tags;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
