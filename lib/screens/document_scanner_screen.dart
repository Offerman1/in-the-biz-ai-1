import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/vision_scan.dart';

/// Multi-page document scanning screen
/// Allows users to capture multiple pages of a document before processing
/// Supports BOTH camera capture AND gallery/photo library upload
class DocumentScannerScreen extends StatefulWidget {
  final ScanType scanType;
  final Function(DocumentScanSession) onScanComplete;

  const DocumentScannerScreen({
    super.key,
    required this.scanType,
    required this.onScanComplete,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _capturedImages = [];
  final List<Uint8List> _capturedBytes = []; // For web compatibility
  final List<String> _mimeTypes = []; // For web compatibility
  bool _isCapturing = false;

  /// Pick multiple images from gallery (like attaching to email)
  Future<void> _pickMultipleImages() async {
    print('🖼️ _pickMultipleImages called');
    if (_isCapturing) {
      print('🖼️ Already capturing, returning');
      return;
    }

    setState(() => _isCapturing = true);

    try {
      print('🖼️ Opening image picker...');
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      print('🖼️ Picker returned ${images.length} images');

      if (images.isNotEmpty) {
        for (final image in images) {
          // Read bytes for web compatibility
          final bytes = await image.readAsBytes();
          final mimeType = image.mimeType ?? 'image/jpeg';

          setState(() {
            _capturedImages.add(image.path);
            _capturedBytes.add(bytes);
            _mimeTypes.add(mimeType);
            print('🖼️ Added image: ${image.path} (${bytes.length} bytes)');
          });
        }

        print('🖼️ Total images now: ${_capturedImages.length}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${images.length} image${images.length == 1 ? '' : 's'} added'),
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.9),
              duration: const Duration(seconds: 2),
            ),
          );

          // Show "add more or finish" prompt
          print('🖼️ About to show add more prompt...');
          await Future.delayed(const Duration(milliseconds: 300));
          _showAddMorePrompt();
        }
      } else {
        print('🖼️ No images selected');
        // User cancelled - if no images captured, go back
        if (_capturedImages.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('🖼️ ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        // Read bytes for web compatibility
        final bytes = await image.readAsBytes();
        final mimeType = image.mimeType ?? 'image/jpeg';

        setState(() {
          _capturedImages.add(image.path);
          _capturedBytes.add(bytes);
          _mimeTypes.add(mimeType);
        });

        // Show "Scan another page?" prompt after a short delay
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          _showAddMorePrompt();
        }
      } else {
        // User cancelled camera - if no images captured, go back
        if (_capturedImages.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Show prompt to add more pages (camera or gallery)
  void _showAddMorePrompt() {
    print('📋 _showAddMorePrompt called');
    print('📋 Current images count: ${_capturedImages.length}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                '${_capturedImages.length} page${_capturedImages.length == 1 ? '' : 's'} scanned',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to process your document?',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // FINISH & PROCESS - PRIMARY ACTION (most prominent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('✅ Finish button tapped!');
                    Navigator.pop(context);
                    _finishScanning();
                  },
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text('Finish & Process'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider with "or add more" text
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: AppTheme.textMuted.withValues(alpha: 0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or add more pages',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: AppTheme.textMuted.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 16),

              // Secondary actions row
              Row(
                children: [
                  // Take another photo - secondary
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _captureImage();
                      },
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(
                            color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Upload more from gallery - secondary
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickMultipleImages();
                      },
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(
                            color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishScanning() {
    print('🔍 _finishScanning called');
    print('🔍 _capturedImages.length: ${_capturedImages.length}');
    print('🔍 _capturedBytes.length: ${_capturedBytes.length}');

    if (_capturedImages.isEmpty && _capturedBytes.isEmpty) {
      print('🔍 No images, popping');
      Navigator.pop(context);
      return;
    }

    print('🔍 Creating session with ${_capturedImages.length} images');
    print('🔍 Scan type: ${widget.scanType}');
    print('🔍 Image paths: $_capturedImages');
    print('🔍 Is web: $kIsWeb');

    final session = DocumentScanSession(
      scanType: widget.scanType,
      imagePaths: _capturedImages,
      imageBytes: _capturedBytes,
      mimeTypes: _mimeTypes,
    );

    print('🔍 Calling onScanComplete callback...');
    widget.onScanComplete(session);
    print('🔍 Callback called, now popping screen');
    Navigator.pop(context); // Return to previous screen
  }

  void _deleteImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
      if (index < _capturedBytes.length) {
        _capturedBytes.removeAt(index);
      }
      if (index < _mimeTypes.length) {
        _mimeTypes.removeAt(index);
      }
    });

    if (_capturedImages.isEmpty) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          '${widget.scanType.displayName} Scanner',
          style:
              AppTheme.titleLarge.copyWith(color: AppTheme.adaptiveTextColor),
        ),
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton(
              onPressed: _finishScanning,
              child: Text(
                'DONE',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _capturedImages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pages added yet',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or upload from gallery',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _pickMultipleImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardBackground,
                  child: Row(
                    children: [
                      Text(
                        widget.scanType.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_capturedImages.length} page${_capturedImages.length == 1 ? '' : 's'} added',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Add more pages or tap "Finish" to process',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Image grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          // Image - always use MemoryImage since we have bytes
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                              image: (index < _capturedBytes.length)
                                  ? DecorationImage(
                                      image: MemoryImage(_capturedBytes[index]),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            // Fallback for when bytes aren't available
                            child: (index >= _capturedBytes.length)
                                ? const Center(
                                    child: Icon(Icons.image,
                                        color: Colors.grey, size: 48))
                                : null,
                          ),

                          // Page number badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Page ${index + 1}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Delete button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _deleteImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Camera and Gallery row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _captureImage,
                                icon: const Icon(Icons.camera_alt, size: 20),
                                label: const Text('Camera'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side:
                                      BorderSide(color: AppTheme.primaryGreen),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickMultipleImages,
                                icon: const Icon(Icons.photo_library, size: 20),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side:
                                      BorderSide(color: AppTheme.primaryGreen),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Finish button (full width)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _finishScanning,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Finish & Process'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
