import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/geo_position.dart';

class LocationNotifier extends AsyncNotifier<GeoPosition> {
  @override
  Future<GeoPosition> build() async {
    return _determinePosition();
  }

  Future<GeoPosition> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return GeoPosition.fallback;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return GeoPosition.fallback;
    }
    if (permission == LocationPermission.deniedForever) {
      return GeoPosition.fallback;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoPosition(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } catch (_) {
      return GeoPosition.fallback;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_determinePosition);
  }
}

final locationNotifierProvider =
    AsyncNotifierProvider<LocationNotifier, GeoPosition>(
  LocationNotifier.new,
);
