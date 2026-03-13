import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/player_level.dart';
import '../../auth/application/auth_notifier.dart';

const _prefXp = 'player_xp';

const xpJoinLobby = 5;
const xpCreateNote = 10;
const xpCreateCta = 15;

class XpNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final localXp = prefs.getInt(_prefXp) ?? 0;

    // Try to sync from Supabase in background
    final player = ref.read(authNotifierProvider).valueOrNull;
    if (player != null) {
      try {
        final data = await Supabase.instance.client
            .from('players')
            .select('xp')
            .eq('id', player.id)
            .single();
        final remoteXp = data['xp'] as int? ?? 0;
        final merged = remoteXp > localXp ? remoteXp : localXp;
        if (merged != localXp) {
          await prefs.setInt(_prefXp, merged);
        }
        return merged;
      } catch (_) {}
    }
    return localXp;
  }

  Future<void> addXp(int amount) async {
    final current = state.valueOrNull ?? 0;
    final newXp = current + amount;
    state = AsyncData(newXp);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefXp, newXp);

    final player = ref.read(authNotifierProvider).valueOrNull;
    if (player != null) {
      try {
        await Supabase.instance.client
            .from('players')
            .update({'xp': newXp})
            .eq('id', player.id);
      } catch (_) {}
    }
  }

  PlayerLevel get playerLevel => PlayerLevel(state.valueOrNull ?? 0);
}

final xpNotifierProvider = AsyncNotifierProvider<XpNotifier, int>(
  XpNotifier.new,
);

final playerLevelProvider = Provider<PlayerLevel>((ref) {
  final xp = ref.watch(xpNotifierProvider).valueOrNull ?? 0;
  return PlayerLevel(xp);
});
