import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/player.dart';
import '../infrastructure/supabase_auth_repository.dart';
import '../../../core/result/result.dart';

class AuthNotifier extends AsyncNotifier<Player?> {
  late final SupabaseAuthRepository _repo;

  @override
  Future<Player?> build() async {
    _repo = SupabaseAuthRepository();
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        state = const AsyncData(null);
      }
    });
    return _repo.currentPlayer;
  }

  Future<Result<Player>> signIn({
    required String nickname,
    String? email,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.signIn(nickname: nickname, email: email);
    state = AsyncData(result.valueOrNull);
    return result;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, Player?>(
  AuthNotifier.new,
);
