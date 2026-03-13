import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/result/result.dart';

class SupabaseStorageRepository {
  SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'marker-images';

  Future<Result<String>> uploadImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final path = '${const Uuid().v4()}.$extension';
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: false,
            ),
          );
      final url = _client.storage.from(_bucket).getPublicUrl(path);
      return Ok(url);
    } catch (e) {
      return Err(e.toString());
    }
  }
}
