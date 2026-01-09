import 'dart:typed_data';

/// Read file bytes from a path - NOT SUPPORTED ON WEB
/// On web, we use bytes directly from the image picker
Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError('readFileBytes is not supported on web');
}

/// Get File object for upload - NOT SUPPORTED ON WEB
dynamic getFileForUpload(String path) {
  throw UnsupportedError('getFileForUpload is not supported on web');
}
