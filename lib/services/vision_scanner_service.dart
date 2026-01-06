import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vision_scan.dart';

/// Service for AI Vision Scanner operations
/// Handles image upload, Edge Function calls, and result processing
class VisionScannerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload images to Supabase Storage and get public URLs
  Future<List<String>> uploadImagesToStorage(
    List<String> imagePaths,
    ScanType scanType,
    String userId,
  ) async {
    final List<String> uploadedUrls = [];

    // Get the appropriate bucket based on scan type
    final bucketName = _getBucketName(scanType);

    for (int i = 0; i < imagePaths.length; i++) {
      final file = File(imagePaths[i]);
      final fileExt = imagePaths[i].split('.').last;
      final fileName =
          '${userId}/${DateTime.now().millisecondsSinceEpoch}_page${i + 1}.$fileExt';

      // Upload to Supabase Storage
      await _supabase.storage.from(bucketName).upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final url = _supabase.storage.from(bucketName).getPublicUrl(fileName);
      uploadedUrls.add(url);
    }

    return uploadedUrls;
  }

  /// Get base64 encoded images for Edge Function
  Future<List<Map<String, String>>> getBase64Images(
      List<String> imagePaths) async {
    final List<Map<String, String>> base64Images = [];

    for (final path in imagePaths) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);

      // Determine MIME type
      String mimeType = 'image/jpeg';
      if (path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.toLowerCase().endsWith('.jpg') ||
          path.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      base64Images.add({
        'data': base64,
        'mimeType': mimeType,
      });
    }

    return base64Images;
  }

  /// Analyze BEO document
  Future<Map<String, dynamic>> analyzeBEO(
    List<String> imagePaths,
    String userId,
  ) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'analyze-beo',
      body: {
        'images': base64Images,
        'userId': userId,
      },
    );

    if (response.status != 200) {
      throw Exception('BEO analysis failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Analyze server checkout
  Future<Map<String, dynamic>> analyzeCheckout(
    List<String> imagePaths,
    String userId, {
    String? shiftId,
    bool forceNew = false,
  }) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'analyze-checkout',
      body: {
        'images': base64Images,
        'userId': userId,
        'shiftId': shiftId,
        'forceNew': forceNew,
      },
    );

    if (response.status != 200) {
      throw Exception('Checkout analysis failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Analyze paycheck
  Future<Map<String, dynamic>> analyzePaycheck(
    List<String> imagePaths,
    String userId,
  ) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'analyze-paycheck',
      body: {
        'images': base64Images,
        'userId': userId,
      },
    );

    if (response.status != 200) {
      throw Exception('Paycheck analysis failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Scan business card
  Future<Map<String, dynamic>> scanBusinessCard(
    List<String> imagePaths,
    String userId, {
    String? shiftId,
  }) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'scan-business-card',
      body: {
        'images': base64Images,
        'userId': userId,
        'shiftId': shiftId,
      },
    );

    if (response.status != 200) {
      throw Exception('Business card scan failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Analyze invoice
  Future<Map<String, dynamic>> analyzeInvoice(
    List<String> imagePaths,
    String userId, {
    String? shiftId,
  }) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'analyze-invoice',
      body: {
        'images': base64Images,
        'userId': userId,
        'shiftId': shiftId,
      },
    );

    if (response.status != 200) {
      throw Exception('Invoice analysis failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Analyze receipt for expense tracking
  Future<Map<String, dynamic>> analyzeReceipt(
    List<String> imagePaths,
    String userId, {
    String? shiftId,
  }) async {
    final base64Images = await getBase64Images(imagePaths);

    final response = await _supabase.functions.invoke(
      'analyze-receipt',
      body: {
        'images': base64Images,
        'userId': userId,
        'shiftId': shiftId,
      },
    );

    if (response.status != 200) {
      throw Exception('Receipt analysis failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Get bucket name based on scan type
  String _getBucketName(ScanType scanType) {
    switch (scanType) {
      case ScanType.beo:
        return 'beo-scans';
      case ScanType.checkout:
        return 'checkout-scans';
      case ScanType.paycheck:
        return 'paycheck-scans';
      case ScanType.businessCard:
        return 'business-card-scans';
      case ScanType.invoice:
        return 'invoice-scans';
      case ScanType.receipt:
        return 'receipt-scans';
    }
  }

  /// Log scan error for debugging
  Future<void> logScanError({
    required ScanType scanType,
    required String errorType,
    required String errorMessage,
    Map<String, dynamic>? aiResponse,
    int? imageCount,
    String? userFeedback,
  }) async {
    try {
      await _supabase.from('vision_scan_errors').insert({
        'scan_type': scanType.name,
        'error_type': errorType,
        'error_message': errorMessage,
        'ai_response': aiResponse,
        'image_count': imageCount,
        'user_feedback': userFeedback,
        'user_flagged': userFeedback != null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log scan error: $e');
    }
  }
}
