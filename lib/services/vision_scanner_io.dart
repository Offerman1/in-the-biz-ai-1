import 'dart:io';
import 'dart:typed_data';

/// Read file bytes from a path (mobile/desktop only)
Future<Uint8List> readFileBytes(String path) async {
  final file = File(path);
  return await file.readAsBytes();
}

/// Get File object for upload (mobile/desktop only)
dynamic getFileForUpload(String path) {
  return File(path);
}
