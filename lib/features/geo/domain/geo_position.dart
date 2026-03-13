class GeoPosition {
  const GeoPosition({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
  });

  final double lat;
  final double lng;
  final double? accuracyMeters;

  // Default fallback (Offenburg, Germany)
  static const fallback = GeoPosition(lat: 48.4741, lng: 7.9462);
}
