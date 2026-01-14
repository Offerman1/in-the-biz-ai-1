import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Unified service for uploading and managing scan images
/// Supports all scan types: BEO, Paycheck, Invoice, Receipt, Business Card, Server Checkout
///
/// Storage bucket: 'shift-attachments' (existing bucket that works)
/// Folder structure: {userId}/{scanType}/{uuid}.jpg (userId MUST be first for RLS)
///
/// Image optimization:
/// - Max dimension: 1500px (preserves detail for text/documents)
/// - Quality: 85% JPEG compression
/// - Average file size: 100-300KB per image
class ScanImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'shift-attachments'; // Use existing bucket

  // Max image dimension (width or height) - 1500px is good for document readability
  static const int _maxDimension = 1500;

  // JPEG quality (0-100) - 85 is a good balance of quality and size
  static const int _jpegQuality = 85;

  /// Upload images from file paths (mobile)
  /// Returns list of public URLs
  Future<List<String>> uploadFromPaths({
    required List<String> imagePaths,
    required String scanType,
    String? entityId, // BEO ID, shift ID, etc.
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final uploadedUrls = <String>[];

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final file = File(imagePath);

      if (!await file.exists()) {
        print('ScanImageService: File not found: $imagePath');
        continue;
      }

      try {
        // Read and optimize the image
        final bytes = await file.readAsBytes();
        final optimizedBytes = await _optimizeImage(bytes);

        // Generate storage path with NO scans/ prefix (unified with gallery)
        final fileId = entityId ?? const Uuid().v4();
        final storagePath = '$userId/$scanType/${fileId}_page${i + 1}.jpg';

        // Upload to Supabase Storage
        await _supabase.storage.from(_bucketName).uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Store storage path (like gallery photos)
        uploadedUrls.add(storagePath);

        print(
            'ScanImageService: Uploaded $storagePath (${optimizedBytes.length ~/ 1024}KB)');
      } catch (e) {
        print('ScanImageService: Error uploading $imagePath: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Upload images from bytes (web compatible)
  /// Returns list of public URLs
  Future<List<String>> uploadFromBytes({
    required List<Uint8List> imageBytes,
    required String scanType,
    String? entityId,
    List<String>? mimeTypes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final uploadedUrls = <String>[];

    for (int i = 0; i < imageBytes.length; i++) {
      final bytes = imageBytes[i];

      try {
        // Optimize the image
        final optimizedBytes = await _optimizeImage(bytes);

        // Generate storage path - userId MUST be first for RLS policy
        final fileId = entityId ?? const Uuid().v4();
        final storagePath = '$userId/$scanType/${fileId}_page${i + 1}.jpg';

        // Upload to Supabase Storage
        await _supabase.storage.from(_bucketName).uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Store storage path (like gallery photos)
        uploadedUrls.add(storagePath);

        print(
            'ScanImageService: Uploaded $storagePath (${optimizedBytes.length ~/ 1024}KB)');
      } catch (e) {
        print('ScanImageService: Error uploading image $i: $e');
      }
    }

    return uploadedUrls;
  }

  /// Optimize image for storage
  /// - Resize if larger than max dimension
  /// - Convert to JPEG with quality compression
  /// - Typically reduces file size by 50-80%
  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('ScanImageService: Could not decode image, returning original');
        return bytes;
      }

      // Calculate new dimensions if needed
      img.Image resized = image;
      if (image.width > _maxDimension || image.height > _maxDimension) {
        if (image.width > image.height) {
          // Landscape - constrain width
          resized = img.copyResize(image, width: _maxDimension);
        } else {
          // Portrait - constrain height
          resized = img.copyResize(image, height: _maxDimension);
        }
        print(
            'ScanImageService: Resized ${image.width}x${image.height} -> ${resized.width}x${resized.height}');
      }

      // Encode as JPEG with quality compression
      final optimized = img.encodeJpg(resized, quality: _jpegQuality);

      print(
          'ScanImageService: Optimized ${bytes.length ~/ 1024}KB -> ${optimized.length ~/ 1024}KB');

      return Uint8List.fromList(optimized);
    } catch (e) {
      print('ScanImageService: Optimization failed, returning original: $e');
      return bytes;
    }
  }

  /// Delete images for an entity (when deleting a BEO, paycheck, etc.)
  Future<void> deleteImages({
    required List<String> imageUrls,
  }) async {
    for (final url in imageUrls) {
      try {
        // Extract storage path from URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // Find the bucket name index and get everything after it
        final bucketIndex = pathSegments.indexOf(_bucketName);
        if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
          final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await _supabase.storage.from(_bucketName).remove([storagePath]);
          print('ScanImageService: Deleted $storagePath');
        }
      } catch (e) {
        print('ScanImageService: Error deleting image: $e');
      }
    }
  }

  /// Upload scan images to BOTH shift-attachments AND dedicated scan bucket
  /// Also creates shift_attachments table entries if shiftId provided
  /// Returns storage paths from shift-attachments bucket
  Future<List<String>> uploadScanToShiftAttachments({
    required List<String>? imagePaths,
    required List<Uint8List>? imageBytes,
    required String scanType,
    required String entityId, // Receipt ID, Invoice ID, Checkout ID, etc.
    String? shiftId, // If provided, creates shift_attachments entries
    List<String>? mimeTypes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final shiftAttachmentPaths = <String>[];

    // Determine number of images
    final imageCount = imagePaths?.length ?? imageBytes?.length ?? 0;
    if (imageCount == 0) return shiftAttachmentPaths;

    for (int i = 0; i < imageCount; i++) {
      try {
        Uint8List optimizedBytes;

        // Get image bytes
        if (imageBytes != null && i < imageBytes.length) {
          optimizedBytes = await _optimizeImage(imageBytes[i]);
        } else if (imagePaths != null && i < imagePaths.length) {
          final file = File(imagePaths[i]);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          optimizedBytes = await _optimizeImage(bytes);
        } else {
          continue;
        }

        // Storage path for shift-attachments bucket
        final storagePath = '$userId/$scanType/${entityId}_page${i + 1}.jpg';

        // 1. Upload to shift-attachments bucket (for in-app preview)
        await _supabase.storage.from(_bucketName).uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        shiftAttachmentPaths.add(storagePath);
        print('✅ Uploaded to shift-attachments: $storagePath');

        // 2. Also upload to dedicated scan bucket (for financial records)
        final dedicatedBucket = _getDedicatedBucket(scanType);
        if (dedicatedBucket != null) {
          try {
            await _supabase.storage.from(dedicatedBucket).uploadBinary(
                  storagePath,
                  optimizedBytes,
                  fileOptions: const FileOptions(
                    contentType: 'image/jpeg',
                    upsert: true,
                  ),
                );
            print('✅ Also uploaded to $dedicatedBucket: $storagePath');
          } catch (e) {
            print('⚠️  Failed to upload to $dedicatedBucket: $e');
            // Continue - shift-attachments upload succeeded
          }
        }

        // 3. Create shift_attachments table entry if linked to shift
        if (shiftId != null) {
          await _supabase.from('shift_attachments').insert({
            'shift_id': shiftId,
            'user_id': userId,
            'file_name': '${entityId}_page${i + 1}.jpg',
            'file_path': storagePath,
            'file_type': 'image',
            'file_size': optimizedBytes.length,
            'file_extension': '.jpg',
          });
          print('✅ Created shift_attachments entry for shift $shiftId');
        }
      } catch (e) {
        print('❌ Error uploading image $i: $e');
        // Continue with other images
      }
    }

    return shiftAttachmentPaths;
  }

  /// Get dedicated bucket name for scan type
  String? _getDedicatedBucket(String scanType) {
    switch (scanType.toLowerCase()) {
      case 'checkout':
        return 'checkout-scans';
      case 'invoice':
        return 'invoice-scans';
      case 'receipt':
        return 'receipt-scans';
      case 'business_card':
        return 'business-card-scans';
      // BEO and paycheck don't need dual upload
      case 'beo':
      case 'paycheck':
        return null;
      default:
        return null;
    }
  }

  /// Get scan type folder name for storage organization
  static String getScanTypeFolder(String scanType) {
    switch (scanType.toLowerCase()) {
      case 'beo':
        return 'beo';
      case 'checkout':
        return 'checkout';
      case 'paycheck':
        return 'paycheck';
      case 'invoice':
        return 'invoice';
      case 'receipt':
        return 'receipt';
      case 'businesscard':
      case 'business_card':
        return 'business_card';
      default:
        return 'other';
    }
  }
}
