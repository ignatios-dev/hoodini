import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/player.dart';
import '../../../core/result/result.dart';

class SupabaseAuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Player? get currentPlayer {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return Player(
      id: user.id,
      nickname: meta['nickname'] as String? ?? 'Unknown',
      email: meta['email'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Future<Result<Player>> signIn({
    required String nickname,
    String? email,
  }) async {
    try {
      final res = await _client.auth.signInAnonymously(
        data: {
          'nickname': nickname,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final user = res.user;
      if (user == null) return const Err('Sign in failed');

      await _client.from('players').upsert({
        'id': user.id,
        'nickname': nickname,
        if (email != null && email.isNotEmpty) 'email': email,
      });

      return Ok(Player(
        id: user.id,
        nickname: nickname,
        email: email?.isNotEmpty == true ? email : null,
        createdAt: DateTime.parse(user.createdAt),
      ));
    } on AuthException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
