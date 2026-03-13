import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<(Uint8List, String)?> pickImageFromDevice() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes == null) return null;
  return (file.bytes!, (file.extension ?? 'jpg').toLowerCase());
}
