import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Unified service for uploading and managing scan images
/// Supports all scan types: BEO, Paycheck, Invoice, Receipt, Business Card, Server Checkout
///
/// Storage bucket: 'shift-attachments' (existing bucket for shift-related files)
/// Folder structure: {userId}/scans/{scanType}/{uuid}.jpg (userId MUST be first for RLS)
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

        // Generate storage path with scans/ prefix
        final fileId = entityId ?? const Uuid().v4();
        final storagePath =
            'scans/$userId/$scanType/${fileId}_page${i + 1}.jpg';

        // Upload to Supabase Storage
        await _supabase.storage.from(_bucketName).uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Get signed URL (private bucket)
        final signedUrl = await _supabase.storage
            .from(_bucketName)
            .createSignedUrl(storagePath, 3600); // 1 hour expiry
        uploadedUrls.add(signedUrl);

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
        final storagePath =
            '$userId/scans/$scanType/${fileId}_page${i + 1}.jpg';

        // Upload to Supabase Storage
        await _supabase.storage.from(_bucketName).uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Get signed URL (private bucket)
        final signedUrl = await _supabase.storage
            .from(_bucketName)
            .createSignedUrl(storagePath, 3600); // 1 hour expiry
        uploadedUrls.add(signedUrl);

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
