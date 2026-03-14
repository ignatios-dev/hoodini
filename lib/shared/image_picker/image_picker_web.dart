// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

const _maxSizePx = 1200;
const _jpegQuality = 0.82;
const _hardLimitBytes = 10 * 1024 * 1024; // 10 MB — reject before reading

/// Returns (bytes, ext) on success.
/// Returns null if the user cancelled without selecting a file.
/// Throws a [String] error message if something went wrong — show to user.
Future<(Uint8List, String)?> pickImageFromDevice() {
  final completer = Completer<(Uint8List, String)?>();
  bool handled = false;

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.cssText =
        'position:fixed;top:-9999px;left:-9999px;opacity:0;width:1px;height:1px;';

  html.document.body!.append(input);

  void completeOk((Uint8List, String) value) {
    if (!completer.isCompleted) {
      input.remove();
      completer.complete(value);
    }
  }

  void completeCancel() {
    if (!completer.isCompleted) {
      input.remove();
      completer.complete(null);
    }
  }

  void completeError(String msg) {
    if (!completer.isCompleted) {
      input.remove();
      completer.completeError(msg);
    }
  }

  void handleEvent(html.Event _) {
    if (handled) return;
    handled = true;

    final files = input.files;
    if (files == null || files.isEmpty) {
      completeCancel();
      return;
    }

    final file = files[0]!;
    debugPrint('[Picker] selected: ${file.name} (${(file.size / 1024).toStringAsFixed(0)} KB)');

    if (file.size > _hardLimitBytes) {
      completeError(
          'Bild zu groß (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB). '
          'Bitte ein Bild unter 10 MB wählen.');
      return;
    }

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! String) {
        completeError('Bild konnte nicht gelesen werden.');
        return;
      }

      // Try resize — fall back to raw bytes if Canvas fails on mobile
      _resizeOrRaw(result, file).then(completeOk).catchError((e) {
        debugPrint('[Picker] all attempts failed: $e');
        completeError('Bild konnte nicht verarbeitet werden. '
            'Bitte ein kleineres JPG/PNG wählen.');
      });
    });

    reader.onError.listen((_) {
      completeError('Fehler beim Lesen des Bildes.');
    });

    reader.readAsDataUrl(file);
  }

  input.addEventListener('change', handleEvent);
  input.addEventListener('input', handleEvent);
  input.click();

  return completer.future;
}

/// Try Canvas resize; if that fails, return original bytes (no resize).
Future<(Uint8List, String)> _resizeOrRaw(
    String dataUrl, html.File file) async {
  try {
    final resized = await _canvasResize(dataUrl)
        .timeout(const Duration(seconds: 15));
    if (resized != null) return resized;
  } catch (e) {
    debugPrint('[Picker] canvas resize failed: $e — using raw bytes');
  }

  // Fallback: use raw bytes as-is
  final comma = dataUrl.indexOf(',');
  if (comma == -1) throw 'Ungültiges Bildformat';
  final bytes = base64Decode(dataUrl.substring(comma + 1));
  final ext = file.name.contains('.')
      ? file.name.split('.').last.toLowerCase()
      : 'jpeg';
  debugPrint('[Picker] raw fallback: ${bytes.length} bytes ext=$ext');
  return (bytes, ext);
}

Future<(Uint8List, String)?> _canvasResize(String dataUrl) async {
  final imgCompleter = Completer<html.ImageElement>();
  final img = html.ImageElement();
  img.onLoad.listen((_) => imgCompleter.complete(img));
  img.onError.listen((_) => imgCompleter.completeError('img load error'));
  img.src = dataUrl;

  final loaded = await imgCompleter.future;
  int w = loaded.naturalWidth;
  int h = loaded.naturalHeight;
  if (w == 0 || h == 0) return null;

  if (w > _maxSizePx || h > _maxSizePx) {
    if (w >= h) {
      h = (h * _maxSizePx / w).round();
      w = _maxSizePx;
    } else {
      w = (w * _maxSizePx / h).round();
      h = _maxSizePx;
    }
  }

  debugPrint('[Picker] canvas resize → ${w}x$h');
  final canvas = html.CanvasElement(width: w, height: h);
  canvas.context2D.drawImageScaled(loaded, 0, 0, w, h);

  final out = canvas.toDataUrl('image/jpeg', _jpegQuality);
  final comma = out.indexOf(',');
  if (comma == -1) return null;

  final bytes = base64Decode(out.substring(comma + 1));
  debugPrint('[Picker] compressed to ${bytes.length} bytes');
  return (bytes, 'jpeg');
}
