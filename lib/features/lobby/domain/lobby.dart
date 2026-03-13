enum LobbyVisibility { public, private }

class Lobby {
  const Lobby({
    required this.id,
    required this.name,
    required this.visibility,
    this.createdBy,
    required this.createdAt,
    this.memberCount = 1,
    this.description,
    this.centerLat,
    this.centerLng,
    this.radiusKm = 30,
  });

  final String id;
  final String name;
  final LobbyVisibility visibility;
  final String? createdBy;
  final DateTime createdAt;
  final int memberCount;
  final String? description;
  final double? centerLat;
  final double? centerLng;
  final int radiusKm;
}
