class ShiftAttachment {
  final String id;
  final String shiftId;
  final String userId;
  final String fileName;
  final String filePath;
  final String fileType; // MIME type
  final int? fileSize; // Size in bytes
  final String? fileExtension;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShiftAttachment({
    required this.id,
    required this.shiftId,
    required this.userId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.fileSize,
    this.fileExtension,
    required this.createdAt,
    this.updatedAt,
  });

  // Get file extension from file name if not stored
  String get extension {
    if (fileExtension != null && fileExtension!.isNotEmpty) {
      return fileExtension!;
    }
    final parts = fileName.split('.');
    return parts.length > 1 ? '.${parts.last.toLowerCase()}' : '';
  }

  // Get human-readable file size
  String get formattedSize {
    if (fileSize == null) return 'Unknown size';
    final kb = fileSize! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  // Determine if this is an image file
  bool get isImage {
    final imageTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/heic'
    ];
    return imageTypes.contains(fileType.toLowerCase()) ||
        ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic']
            .contains(extension.toLowerCase());
  }

  // Determine if this is a video file
  bool get isVideo {
    final videoTypes = [
      'video/mp4',
      'video/quicktime',
      'video/avi',
      'video/mov'
    ];
    return videoTypes.contains(fileType.toLowerCase()) ||
        ['.mp4', '.mov', '.avi', '.mkv'].contains(extension.toLowerCase());
  }

  // Determine if this is a PDF
  bool get isPdf {
    return fileType.toLowerCase() == 'application/pdf' ||
        extension.toLowerCase() == '.pdf';
  }

  // Determine if this is a document
  bool get isDocument {
    final docTypes = [
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ];
    final docExtensions = ['.doc', '.docx', '.txt', '.rtf'];
    return docTypes.contains(fileType.toLowerCase()) ||
        docExtensions.contains(extension.toLowerCase());
  }

  // Determine if this is a spreadsheet
  bool get isSpreadsheet {
    final sheetTypes = [
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv',
    ];
    final sheetExtensions = ['.xls', '.xlsx', '.csv'];
    return sheetTypes.contains(fileType.toLowerCase()) ||
        sheetExtensions.contains(extension.toLowerCase());
  }

  // Get icon name based on file type
  String get iconName {
    if (isImage) return 'image';
    if (isVideo) return 'video';
    if (isPdf) return 'pdf';
    if (isDocument) return 'document';
    if (isSpreadsheet) return 'spreadsheet';
    return 'file';
  }

  // Get public URL for the attachment
  // Note: This requires the Supabase client instance, so we'll create a helper method in DatabaseService
  // For now, return the file path which can be used to generate URL
  String get storagePath => filePath;

  // Convert from database map
  factory ShiftAttachment.fromMap(Map<String, dynamic> map) {
    return ShiftAttachment(
      id: map['id'] as String,
      shiftId: map['shift_id'] as String,
      userId: map['user_id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      fileSize: map['file_size'] as int?,
      fileExtension: map['file_extension'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shift_id': shiftId,
      'user_id': userId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'file_extension': fileExtension,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy with modifications
  ShiftAttachment copyWith({
    String? id,
    String? shiftId,
    String? userId,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? fileExtension,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftAttachment(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
