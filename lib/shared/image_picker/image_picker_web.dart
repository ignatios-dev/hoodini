// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

Future<(Uint8List, String)?> pickImageFromDevice() {
  final completer = Completer<(Uint8List, String)?>();

  // Position off-screen — NOT display:none, which blocks change events on iOS
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.cssText = 'position:fixed;top:-9999px;left:-9999px;opacity:0;width:1px;height:1px;';

  html.document.body!.append(input);
  debugPrint('[Picker] input appended, waiting for file...');

  void complete((Uint8List, String)? value) {
    if (!completer.isCompleted) {
      input.remove();
      completer.complete(value);
    }
  }

  void onFileReady(html.File file) {
    debugPrint('[Picker] reading file: ${file.name} (${file.size} bytes)');
    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      debugPrint('[Picker] FileReader done — type: ${result.runtimeType}');
      if (result is ByteBuffer) {
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        debugPrint('[Picker] success: ext=$ext bytes=${result.lengthInBytes}');
        complete((result.asUint8List(), ext));
      } else {
        debugPrint('[Picker] unexpected result type, returning null');
        complete(null);
      }
    });

    reader.onError.listen((e) {
      debugPrint('[Picker] FileReader error: $e');
      complete(null);
    });

    reader.readAsArrayBuffer(file);
  }

  // Listen to both 'change' and 'input' — some browsers fire one, some the other
  void handleEvent(html.Event _) {
    debugPrint('[Picker] file event fired, files count: ${input.files?.length}');
    final files = input.files;
    if (files == null || files.isEmpty) {
      debugPrint('[Picker] no files in event');
      complete(null);
      return;
    }
    onFileReady(files[0]!);
  }

  input.addEventListener('change', handleEvent);
  input.addEventListener('input', handleEvent);

  input.click();
  debugPrint('[Picker] click() called');

  return completer.future;
}
