import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/shift_attachment.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../screens/full_screen_document_viewer.dart';
import 'package:open_filex/open_filex.dart';

/// Universal document preview widget
/// - Images: Shows thumbnail preview
/// - PDFs: Shows first page preview
/// - Excel/Word/Other: Shows file type icon
class DocumentPreviewWidget extends StatefulWidget {
  final ShiftAttachment attachment;
  final double height;
  final double width;
  final bool showFileName;
  final bool showFileSize;

  const DocumentPreviewWidget({
    super.key,
    required this.attachment,
    this.height = 120,
    this.width = double.infinity,
    this.showFileName = true,
    this.showFileSize = true,
  });

  @override
  State<DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<DocumentPreviewWidget> {
  final DatabaseService _db = DatabaseService();
  String? _imageUrl;
  bool _isLoadingUrl = true;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage || widget.attachment.isPdf) {
      _loadImageUrl();
    } else {
      _isLoadingUrl = false;
    }
  }

  Future<void> _loadImageUrl() async {
    try {
      final url = await _db.getAttachmentUrl(widget.attachment.storagePath);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoadingUrl = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUrl = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: _getIconColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Preview area
              Expanded(
                child: _buildPreview(context),
              ),
              // File info
              if (widget.showFileName || widget.showFileSize)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusSmall),
                      bottomRight: Radius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showFileName)
                        Text(
                          widget.attachment.fileName,
                          style: AppTheme.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.showFileSize) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.attachment.extension.toUpperCase()} • ${widget.attachment.formattedSize}',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    // Images - show actual preview
    if (widget.attachment.isImage) {
      if (_isLoadingUrl) {
        return Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 2,
          ),
        );
      }

      if (_imageUrl == null) {
        return _buildIconPreview(Icons.image, AppTheme.accentPurple);
      }

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusSmall),
          topRight: Radius.circular(AppTheme.radiusSmall),
        ),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconPreview(Icons.image, AppTheme.accentPurple);
          },
        ),
      );
    }

    // PDFs - show first page preview (for now, use icon)
    // TODO: Implement PDF first-page thumbnail generation
    if (widget.attachment.isPdf) {
      return _buildIconPreview(Icons.picture_as_pdf, AppTheme.accentRed);
    }

    // Excel/Spreadsheets
    if (widget.attachment.isSpreadsheet) {
      return _buildIconPreview(Icons.table_chart, AppTheme.primaryGreen);
    }

    // Word/Documents
    if (widget.attachment.isDocument) {
      return _buildIconPreview(Icons.description, AppTheme.accentBlue);
    }

    // Videos
    if (widget.attachment.isVideo) {
      return _buildIconPreview(Icons.videocam, AppTheme.accentOrange);
    }

    // Generic file
    return _buildIconPreview(Icons.insert_drive_file, AppTheme.textMuted);
  }

  Widget _buildIconPreview(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: color,
        ),
      ),
    );
  }

  Color _getIconColor() {
    if (widget.attachment.isPdf) return AppTheme.accentRed;
    if (widget.attachment.isImage) return AppTheme.accentPurple;
    if (widget.attachment.isVideo) return AppTheme.accentOrange;
    if (widget.attachment.isDocument) return AppTheme.accentBlue;
    if (widget.attachment.isSpreadsheet) return AppTheme.primaryGreen;
    return AppTheme.textMuted;
  }

  Future<void> _handleTap(BuildContext context) async {
    // Images and PDFs - open in full-screen viewer
    if (widget.attachment.isImage || widget.attachment.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenDocumentViewer(
            attachment: widget.attachment,
          ),
        ),
      );
      return;
    }

    // Excel, Word, and other files - open in native app
    if (!kIsWeb) {
      try {
        // Download file to temp location if it's a URL
        final filePath = widget.attachment.storagePath;
        await OpenFilex.open(filePath);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: $e'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    } else {
      // Web - open in new tab
      // TODO: Implement web file opening
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File download not yet implemented for web'),
          ),
        );
      }
    }
  }
}
