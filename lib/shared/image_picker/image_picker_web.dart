// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

Future<(Uint8List, String)?> pickImageFromDevice() {
  final completer = Completer<(Uint8List, String)?>();

  final input = html.FileUploadInputElement()..accept = 'image/*';
  html.document.body!.append(input);

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) {
      input.remove();
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      input.remove();
      final result = reader.result;
      if (result is ByteBuffer) {
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        completer.complete((result.asUint8List(), ext));
      } else {
        completer.complete(null);
      }
    });
  });

  // Trigger synchronously within the user-gesture context
  input.click();

  return completer.future;
}
