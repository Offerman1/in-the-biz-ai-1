/// Document scan session model for AI Vision scanning
class DocumentScanSession {
  final String id;
  final DateTime startedAt;
  final List<String> imagePaths;
  final Map<String, dynamic>? extractedData;
  final bool isComplete;

  DocumentScanSession({
    required this.id,
    required this.startedAt,
    this.imagePaths = const [],
    this.extractedData,
    this.isComplete = false,
  });
}
