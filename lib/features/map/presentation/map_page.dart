import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../shared/image_picker/image_picker_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../auth/application/auth_notifier.dart';
import '../../geo/application/location_notifier.dart';
import '../../lobby/application/lobby_notifier.dart';
import '../../marker/application/marker_notifier.dart';
import '../../marker/domain/marker.dart';
import '../../marker/infrastructure/supabase_storage_repository.dart';
import '../../xp/application/xp_notifier.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/result/result.dart';

const _kTags = [
  ('⚠️', 'danger'),
  ('🍔', 'food'),
  ('🎯', 'meetup'),
  ('🎨', 'art'),
  ('👻', 'mystery'),
  ('🔥', 'hot'),
  ('💬', 'info'),
  ('🚧', 'block'),
];

Color _playerTrailColor(String playerId) {
  const palette = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFFFFA07A),
    Color(0xFFDDA0DD),
    Color(0xFFFFD700),
    Color(0xFF39FF14),
    Color(0xFFFF69B4),
  ];
  final index = playerId.codeUnits.fold(0, (a, b) => a ^ b) % palette.length;
  return palette[index];
}

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _mapController = MapController();
  bool _showTrails = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _showCreateMarkerSheet(LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateMarkerSheet(position: position),
    );
  }

  void _showMarkerDetail(MapMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MarkerDetailSheet(marker: marker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationNotifierProvider);
    final player = ref.watch(authNotifierProvider).valueOrNull;
    final lobby = ref.watch(lobbyNotifierProvider).valueOrNull;
    final markersAsync = ref.watch(markerNotifierProvider);
    final playerLevel = ref.watch(playerLevelProvider);
    final theme = Theme.of(context);

    return locationAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Location error: $e')),
      ),
      data: (location) {
        final center = LatLng(location.lat, location.lng);
        final allMarkers = markersAsync.valueOrNull ?? [];

        final markers = allMarkers;

        // Build player trails: group all markers by player, sorted by time
        final trailMap = <String, List<MapMarker>>{};
        for (final m in allMarkers) {
          trailMap.putIfAbsent(m.createdBy, () => []).add(m);
        }
        final trails = trailMap.entries
            .where((e) => e.value.length > 1)
            .map((e) {
              final sorted = [...e.value]
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              return (e.key, sorted);
            })
            .toList();

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: AppConstants.defaultMapZoom,
                  onLongPress: (tapPosition, latLng) =>
                      _showCreateMarkerSheet(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.hoodini.hoodini',
                  ),
                  // Player trails
                  if (_showTrails)
                    PolylineLayer(
                      polylines: trails
                          .map((t) => Polyline(
                                points: t.$2
                                    .map((m) => LatLng(m.lat, m.lng))
                                    .toList(),
                                color: _playerTrailColor(t.$1)
                                    .withValues(alpha: 0.75),
                                strokeWidth: 2.5,
                              ))
                          .toList(),
                    ),
                  // Player name labels at trail endpoints
                  if (_showTrails)
                    MarkerLayer(
                      markers: trails.map((t) {
                        final last = t.$2.last;
                        final color = _playerTrailColor(t.$1);
                        return Marker(
                          point: LatLng(last.lat, last.lng),
                          width: 90,
                          height: 24,
                          alignment: const Alignment(0, -2.5),
                          child: GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  '${last.creatorNickname} · ${t.$2.length} markers'),
                              duration: const Duration(seconds: 2),
                            )),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                last.creatorNickname,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  // Player location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Game markers
                  MarkerLayer(
                    markers: markers
                        .map(
                          (m) => Marker(
                            point: LatLng(m.lat, m.lng),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () => _showMarkerDetail(m),
                              child: _MarkerIcon(
                                  type: m.type,
                                  creatorLevel: m.creatorLevel,
                                  tags: m.tags),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

              // Top overlay: lobby info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        _HoodChip(
                          icon: Icons.people,
                          label: lobby?.name ?? '',
                        ),
                        const Spacer(),
                        _HoodChip(
                          icon: Icons.person,
                          label:
                              '${player?.nickname ?? ''} · ${playerLevel.title}',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Long-press hint
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '👆 long press map to pin any spot',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom overlay: action buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // XP indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt,
                                  size: 13,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${playerLevel.xp} XP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Refresh markers
                        FloatingActionButton.small(
                          heroTag: 'refresh',
                          tooltip: 'Refresh markers',
                          onPressed: () =>
                              ref.invalidate(markerNotifierProvider),
                          child: const Icon(Icons.refresh),
                        ),
                        const SizedBox(width: 8),
                        // Trail toggle
                        FloatingActionButton.small(
                          heroTag: 'trails',
                          tooltip: 'Player trails',
                          backgroundColor: _showTrails
                              ? theme.colorScheme.primary
                              : null,
                          foregroundColor: _showTrails ? Colors.black : null,
                          onPressed: () =>
                              setState(() => _showTrails = !_showTrails),
                          child: const Icon(Icons.route),
                        ),
                        const SizedBox(width: 8),
                        // Share lobby invite link
                        FloatingActionButton.small(
                          heroTag: 'share',
                          onPressed: () {
                            if (lobby == null) return;
                            final link =
                                'https://hoodini.vercel.app/join/${lobby.id}';
                            Clipboard.setData(ClipboardData(text: link));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Invite link copied – share it with friends!'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          child: const Icon(Icons.share),
                        ),
                        const SizedBox(width: 8),
                        // Center on location
                        FloatingActionButton.small(
                          heroTag: 'locate',
                          tooltip: 'Go to my location',
                          onPressed: () {
                            ref
                                .read(locationNotifierProvider.notifier)
                                .refresh();
                            _mapController.move(
                                center, AppConstants.defaultMapZoom);
                          },
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(width: 8),
                        // Leave lobby
                        FloatingActionButton.small(
                          heroTag: 'leave',
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                          onPressed: () {
                            ref
                                .read(lobbyNotifierProvider.notifier)
                                .leaveLobby();
                          },
                          child: const Icon(Icons.exit_to_app),
                        ),
                        const SizedBox(width: 8),
                        // Add marker at current location
                        FloatingActionButton(
                          heroTag: 'add_marker',
                          tooltip: 'Drop marker at my location',
                          onPressed: () => _showCreateMarkerSheet(center),
                          child: const Icon(Icons.add_location_alt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerIcon extends StatelessWidget {
  const _MarkerIcon(
      {required this.type, this.creatorLevel = 0, this.tags = const []});
  final MarkerType type;
  final int creatorLevel;
  final List<String> tags;

  String? get _emoji => tags.isEmpty
      ? null
      : _kTags.firstWhere((t) => t.$2 == tags.first,
              orElse: () => ('🏷️', tags.first))
          .$1;

  Widget _content(IconData icon, double size, Color iconColor) {
    final em = _emoji;
    if (em != null) {
      return Text(em,
          style: TextStyle(fontSize: size * 0.75),
          textAlign: TextAlign.center);
    }
    return Icon(icon, color: iconColor, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final baseColor = switch (type) {
      MarkerType.note => cs.primary,
      MarkerType.photo => cs.secondary,
      MarkerType.ctaFlag => cs.tertiary,
    };

    final icon = switch (type) {
      MarkerType.note => Icons.sticky_note_2,
      MarkerType.photo => Icons.photo_camera,
      MarkerType.ctaFlag => Icons.flag,
    };

    // Level 0: Ghost – hollow, small
    if (creatorLevel == 0) {
      return Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Center(child: _content(icon, 13, baseColor.withValues(alpha: 0.5))),
      );
    }

    // Level 1: Rookie – solid circle
    if (creatorLevel == 1) {
      return Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)],
        ),
        child: Center(child: _content(icon, 15, Colors.black)),
      );
    }

    // Level 2: Explorer – circle with outer ring
    if (creatorLevel == 2) {
      return Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 6)],
        ),
        child: Center(child: _content(icon, 17, Colors.black)),
      );
    }

    // Level 3: Street Wise – large with strong glow
    if (creatorLevel == 3) {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: baseColor.withValues(alpha: 0.7), blurRadius: 12, spreadRadius: 2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
          ],
        ),
        child: Center(child: _content(icon, 19, Colors.black)),
      );
    }

    // Level 4: Block Boss – diamond shape, gold
    if (creatorLevel == 4) {
      return Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.8), blurRadius: 14, spreadRadius: 3),
            ],
          ),
          child: Transform.rotate(
            angle: -0.785398,
            child: Center(child: _content(icon, 18, Colors.black)),
          ),
        ),
      );
    }

    // Level 5: Hood Legend – large diamond, intense glow
    if (creatorLevel == 5) {
      return Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.9), blurRadius: 20, spreadRadius: 6),
              BoxShadow(color: Colors.orange.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 4),
            ],
          ),
          child: Transform.rotate(
            angle: -0.785398,
            child: Center(child: _content(icon, 20, Colors.black)),
          ),
        ),
      );
    }

    // Level 6: The Hoodini – crown icon, epic
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF6B35), Color(0xFF39FF14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.9), blurRadius: 24, spreadRadius: 8),
              BoxShadow(color: const Color(0xFF39FF14).withValues(alpha: 0.5), blurRadius: 32, spreadRadius: 4),
            ],
          ),
          child: Center(child: _content(icon, 22, Colors.black)),
        ),
        const Positioned(
          top: -10,
          child: Text('👑', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

class _HoodChip extends StatelessWidget {
  const _HoodChip({required this.icon, required this.label, this.highlight = false});
  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? cs.primary : cs.outline,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: highlight ? cs.primary : cs.onSurface),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: highlight ? cs.primary : cs.onSurface,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateMarkerSheet extends ConsumerStatefulWidget {
  const _CreateMarkerSheet({required this.position});
  final LatLng position;

  @override
  ConsumerState<_CreateMarkerSheet> createState() => _CreateMarkerSheetState();
}

class _CreateMarkerSheetState extends ConsumerState<_CreateMarkerSheet> {
  final _textController = TextEditingController();
  MarkerType _type = MarkerType.note;
  final Set<String> _selectedTags = {};
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _uploading = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    debugPrint('[Marker] picking image...');
    final picked = await pickImageFromDevice();
    if (picked == null) {
      debugPrint('[Marker] image pick cancelled');
      return;
    }
    debugPrint('[Marker] picked: ext=${picked.$2} bytes=${picked.$1.length}');
    setState(() {
      _imageBytes = picked.$1;
      _imageExt = picked.$2;
    });
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() { _uploading = true; _uploadStatus = ''; });

    String? imageUrl;
    if (_imageBytes != null && _imageExt != null) {
      setState(() => _uploadStatus = 'uploading image...');
      final uploadResult = await SupabaseStorageRepository().uploadImage(
        bytes: _imageBytes!,
        extension: _imageExt!,
      );
      if (uploadResult.isErr) {
        if (mounted) {
          setState(() { _uploading = false; _uploadStatus = ''; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload fehlgeschlagen: ${uploadResult.errorOrNull}'),
              duration: const Duration(seconds: 6),
              backgroundColor: Colors.red[900],
            ),
          );
        }
        return;
      }
      imageUrl = uploadResult.valueOrNull;
      debugPrint('[Marker] imageUrl to save: $imageUrl');
      setState(() => _uploadStatus = 'saving marker...');
    } else {
      setState(() => _uploadStatus = 'saving...');
    }

    debugPrint('[Marker] createMarker with imageUrl=$imageUrl');
    final result = await ref.read(markerNotifierProvider.notifier).createMarker(
          lat: widget.position.latitude,
          lng: widget.position.longitude,
          text: _textController.text,
          type: _type,
          imageUrl: imageUrl,
          tags: _selectedTags.toList(),
        );

    if (mounted) {
      Navigator.of(context).pop();
      if (result.isErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorOrNull ?? 'Error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '// DROP A MARKER //',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MarkerType>(
            segments: const [
              ButtonSegment(value: MarkerType.note, icon: Icon(Icons.sticky_note_2), label: Text('NOTE')),
              ButtonSegment(value: MarkerType.ctaFlag, icon: Icon(Icons.flag), label: Text('CTA')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          // Tag selector
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kTags.map((t) {
              final (emoji, name) = t;
              final active = _selectedTags.contains(name);
              return GestureDetector(
                onTap: () => setState(() {
                  if (active) {
                    _selectedTags.remove(name);
                  } else {
                    _selectedTags.add(name);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? cs.primary : Colors.white24,
                    ),
                  ),
                  child: Text(
                    '$emoji $name',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: active ? Colors.black : Colors.white70,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'MESSAGE',
              hintText: 'what do you want to leave here?',
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Image picker row
          Row(
            children: [
              Expanded(
                child: _imageBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageBytes!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _imageBytes = null;
                                _imageExt = null;
                              }),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('ADD IMAGE'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_uploadStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _uploadStatus,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: cs.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          FilledButton(
            onPressed: _uploading ? null : _submit,
            child: _uploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('[ DROP IT ]'),
          ),
        ],
      ),
    );
  }
}

class _MarkerDetailSheet extends ConsumerWidget {
  const _MarkerDetailSheet({required this.marker});
  final MapMarker marker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final player = ref.read(authNotifierProvider).valueOrNull;
    final isOwner = player?.id == marker.createdBy;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MarkerIcon(type: marker.type, creatorLevel: marker.creatorLevel, tags: marker.tags),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.creatorNickname,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      _timeAgo(marker.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  onPressed: () {
                    ref
                        .read(markerNotifierProvider.notifier)
                        .deleteMarker(marker.id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (marker.imageUrl != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'img: ${marker.imageUrl}',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                marker.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (ctx, err, st) => Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: theme.colorScheme.error, size: 28),
                      const SizedBox(height: 6),
                      Text('Bild konnte nicht geladen werden',
                          style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(marker.text, style: theme.textTheme.bodyLarge),
          if (marker.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: marker.tags.map((tag) {
                final emoji = _kTags
                    .firstWhere((t) => t.$2 == tag,
                        orElse: () => ('🏷️', tag))
                    .$1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$emoji $tag',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${marker.lat.toStringAsFixed(5)}, ${marker.lng.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
