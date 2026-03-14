import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/result/result.dart';

class SupabaseStorageRepository {
  SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'marker-images';

  // jpg is not a valid MIME subtype — map to correct values
  static String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<Result<String>> uploadImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '${const Uuid().v4()}.${extension.toLowerCase()}';
    final mime = _mimeType(extension);
    debugPrint('[Storage] uploading $path | mime=$mime | bytes=${bytes.length}');

    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      debugPrint('[Storage] upload OK → $url');
      return Ok(url);
    } catch (e, st) {
      debugPrint('[Storage] upload FAILED: $e\n$st');
      return Err(e.toString());
    }
  }
}
