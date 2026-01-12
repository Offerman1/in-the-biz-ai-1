import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../models/shift_attachment.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Universal document preview widget
/// - Images: Shows thumbnail preview
/// - PDFs/Excel/Word/Other: Shows file type icon, opens in native app
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
            color: AppTheme.cardBackgroundLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: _getIconColor().withValues(alpha: 0.3),
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
                    color: Colors.black.withValues(alpha: 0.3),
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

    // PDFs - show icon (opens in native app on tap)
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
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
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
    // All files open in native app (saves bandwidth, uses phone's cache)
    if (!kIsWeb) {
      try {
        // Get signed URL from Supabase
        final url = await _db.getAttachmentUrl(widget.attachment.storagePath);

        // Open URL in native app (browser will handle PDF, image viewer, etc.)
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not open file';
        }
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
      try {
        final url = await _db.getAttachmentUrl(widget.attachment.storagePath);
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    }
  }
}
