// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

Future<(Uint8List, String)?> pickImageFromDevice() {
  final completer = Completer<(Uint8List, String)?>();
  bool handled = false;

  // Off-screen, NOT display:none — blocks change events on iOS Safari
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.cssText = 'position:fixed;top:-9999px;left:-9999px;opacity:0;width:1px;height:1px;';

  html.document.body!.append(input);
  debugPrint('[Picker] ready, waiting for file...');

  void complete((Uint8List, String)? value) {
    if (!completer.isCompleted) {
      input.remove();
      completer.complete(value);
    }
  }

  void handleEvent(html.Event _) {
    // 'change' and 'input' both fire — only handle once
    if (handled) return;
    handled = true;

    final files = input.files;
    debugPrint('[Picker] event fired, files count: ${files?.length}');

    if (files == null || files.isEmpty) {
      debugPrint('[Picker] no file selected');
      complete(null);
      return;
    }

    final file = files[0]!;
    debugPrint('[Picker] reading: ${file.name} (${file.size} bytes)');

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      // Use readAsDataUrl — avoids ByteBuffer type-check which breaks
      // in minified Flutter web builds (dart2js renames types)
      final result = reader.result;
      debugPrint('[Picker] FileReader done, result type: ${result.runtimeType}');

      if (result is! String) {
        debugPrint('[Picker] result is not a String, aborting');
        complete(null);
        return;
      }

      // result = "data:image/jpeg;base64,/9j/4AAQ..."
      final comma = result.indexOf(',');
      if (comma == -1) {
        debugPrint('[Picker] malformed data URL');
        complete(null);
        return;
      }

      try {
        final bytes = base64Decode(result.substring(comma + 1));
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        debugPrint('[Picker] success: ext=$ext bytes=${bytes.length}');
        complete((bytes, ext));
      } catch (e) {
        debugPrint('[Picker] base64 decode failed: $e');
        complete(null);
      }
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
