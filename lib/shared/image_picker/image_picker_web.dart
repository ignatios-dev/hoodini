// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

const _maxSizePx = 1200;     // longest side in pixels
const _jpegQuality = 0.85;   // 0.0–1.0
const _warnBytes = 3 * 1024 * 1024; // warn if original > 3 MB

Future<(Uint8List, String)?> pickImageFromDevice() {
  final completer = Completer<(Uint8List, String)?>();
  bool handled = false;

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.cssText = 'position:fixed;top:-9999px;left:-9999px;opacity:0;width:1px;height:1px;';

  html.document.body!.append(input);

  void complete((Uint8List, String)? value) {
    if (!completer.isCompleted) {
      input.remove();
      completer.complete(value);
    }
  }

  void handleEvent(html.Event _) {
    if (handled) return;
    handled = true;

    final files = input.files;
    if (files == null || files.isEmpty) {
      complete(null);
      return;
    }

    final file = files[0]!;
    debugPrint('[Picker] reading: ${file.name} (${file.size} bytes)');

    if (file.size > _warnBytes) {
      debugPrint('[Picker] large file (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB) — will compress');
    }

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! String) {
        debugPrint('[Picker] unexpected result type');
        complete(null);
        return;
      }

      _resizeAndCompress(result, file.name).then((resized) {
        if (resized == null) {
          complete(null);
          return;
        }
        final (bytes, ext) = resized;
        debugPrint('[Picker] final: ext=$ext bytes=${bytes.length} '
            '(original ${file.size} bytes, '
            '${((1 - bytes.length / file.size) * 100).toStringAsFixed(0)}% smaller)');
        complete((bytes, ext));
      });
    });

    reader.onError.listen((e) {
      debugPrint('[Picker] FileReader error: $e');
      complete(null);
    });

    reader.readAsDataUrl(file);
  }

  input.addEventListener('change', handleEvent);
  input.addEventListener('input', handleEvent);
  input.click();

  return completer.future;
}

/// Resize to max [_maxSizePx] on longest side and re-encode as JPEG.
Future<(Uint8List, String)?> _resizeAndCompress(
    String dataUrl, String filename) async {
  final imgCompleter = Completer<html.ImageElement>();
  final img = html.ImageElement();
  img.onLoad.listen((_) => imgCompleter.complete(img));
  img.onError.listen((_) => imgCompleter.completeError('img load error'));
  img.src = dataUrl;

  try {
    final loaded = await imgCompleter.future;
    int w = loaded.naturalWidth;
    int h = loaded.naturalHeight;

    if (w == 0 || h == 0) {
      debugPrint('[Picker] could not read image dimensions');
      return null;
    }

    // Scale down if needed, preserve aspect ratio
    if (w > _maxSizePx || h > _maxSizePx) {
      if (w >= h) {
        h = (h * _maxSizePx / w).round();
        w = _maxSizePx;
      } else {
        w = (w * _maxSizePx / h).round();
        h = _maxSizePx;
      }
    }

    debugPrint('[Picker] resizing to ${w}x$h at ${(_jpegQuality * 100).round()}% JPEG');

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImageScaled(loaded, 0, 0, w, h);

    final compressed = canvas.toDataUrl('image/jpeg', _jpegQuality);
    final comma = compressed.indexOf(',');
    if (comma == -1) return null;

    final bytes = base64Decode(compressed.substring(comma + 1));
    return (bytes, 'jpeg');
  } catch (e) {
    debugPrint('[Picker] resize failed: $e — returning original');
    // Fall back to original bytes
    final comma = dataUrl.indexOf(',');
    if (comma == -1) return null;
    try {
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      final ext = filename.contains('.')
          ? filename.split('.').last.toLowerCase()
          : 'jpg';
      return (bytes, ext);
    } catch (_) {
      return null;
    }
  }
}
