import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores a lobby ID to auto-join after the user completes sign-in.
/// Set when opening a /join/:lobbyId deep link.
final pendingLobbyIdProvider = StateProvider<String?>((ref) => null);
