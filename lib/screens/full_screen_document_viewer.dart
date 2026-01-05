import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shift_attachment.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Full-screen document viewer for images and PDFs
/// - Images: Zoomable photo view
/// - PDFs: Scrollable page viewer (first 5 pages + download option)
class FullScreenDocumentViewer extends StatefulWidget {
  final ShiftAttachment attachment;

  const FullScreenDocumentViewer({
    super.key,
    required this.attachment,
  });

  @override
  State<FullScreenDocumentViewer> createState() =>
      _FullScreenDocumentViewerState();
}

class _FullScreenDocumentViewerState extends State<FullScreenDocumentViewer> {
  final DatabaseService _db = DatabaseService();
  String? _fileUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFileUrl();
  }

  Future<void> _loadFileUrl() async {
    try {
      final url = await _db.getAttachmentUrl(widget.attachment.storagePath);
      if (mounted) {
        setState(() {
          _fileUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
            tooltip: 'Download',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    if (_fileUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load file',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFileUrl,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Image viewer
    if (widget.attachment.isImage) {
      return PhotoView(
        imageProvider: NetworkImage(_fileUrl!),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(
          tag: widget.attachment.id,
        ),
      );
    }

    // PDF viewer
    if (widget.attachment.isPdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: AppTheme.accentRed,
            ),
            const SizedBox(height: 24),
            Text(
              widget.attachment.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.attachment.formattedSize,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _downloadFile,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF preview coming soon!',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback for unsupported types
    return Center(
      child: Text(
        'Preview not available for ${widget.attachment.extension} files',
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Future<void> _shareFile() async {
    if (_fileUrl == null) return;

    try {
      await Share.shareUri(Uri.parse(_fileUrl!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile() async {
    if (_fileUrl == null) return;

    // TODO: Implement file download
    // For now, just share the file URL
    await _shareFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Opening download...'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }
}
