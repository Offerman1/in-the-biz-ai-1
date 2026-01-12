import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../models/beo_event.dart';

/// Service for generating PDF exports of BEO events
class BeoPdfService {
  final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  /// Generate a PDF for a BEO event and share it
  Future<void> generateAndSharePdf(BeoEvent beo,
      {String? logoUrl, String? companyName}) async {
    final pdf = pw.Document();

    // Try to load logo if provided
    pw.MemoryImage? logoImage;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Failed to load logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(beo, logoImage, companyName),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildContent(beo),
      ),
    );

    // Save and share
    if (kIsWeb) {
      // Web: Download directly
      final bytes = await pdf.save();
      // Web download is handled differently
      debugPrint('PDF generated (${bytes.length} bytes)');
    } else {
      // Mobile: Save to temp and share
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'BEO_${beo.eventName.replaceAll(RegExp(r'[^\w\s]'), '')}_${DateFormat('yyyyMMdd').format(beo.eventDate)}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BEO: ${beo.eventName}',
        text: 'Banquet Event Order for ${beo.eventName}',
      );
    }
  }

  /// Build PDF header with logo and event name
  pw.Widget _buildHeader(
      BeoEvent beo, pw.MemoryImage? logoImage, String? companyName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoImage != null)
            pw.Container(
              width: 80,
              height: 80,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (companyName != null && companyName.isNotEmpty)
                  pw.Text(
                    companyName,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                pw.Text(
                  'BANQUET EVENT ORDER',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  beo.eventName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _dateFormat.format(beo.eventDate),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (beo.eventStartTime != null || beo.eventEndTime != null)
                pw.Text(
                  '${beo.eventStartTime ?? ''} - ${beo.eventEndTime ?? ''}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (beo.eventType != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4),
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    beo.eventType!,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build PDF footer with page numbers
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by In The Biz',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Build main PDF content
  List<pw.Widget> _buildContent(BeoEvent beo) {
    return [
      // Event & Venue Info
      _buildSection('Event Details', [
        _buildInfoRow('Venue', beo.venueName),
        _buildInfoRow('Address', beo.venueAddress),
        _buildInfoRow('Function Space', beo.functionSpace),
        _buildInfoRow('Guest Count', beo.displayGuestCount?.toString()),
      ]),

      // Contact Info
      if (beo.primaryContactName != null || beo.primaryContactPhone != null)
        _buildSection('Contact Information', [
          _buildInfoRow('Host', beo.primaryContactName),
          _buildInfoRow('Phone', beo.primaryContactPhone),
          _buildInfoRow('Email', beo.primaryContactEmail),
        ]),

      // Financials
      if (beo.hasFinancials)
        _buildSection('Financial Summary', [
          _buildInfoRow('Food Total', _formatMoney(beo.foodTotal)),
          _buildInfoRow('Beverage Total', _formatMoney(beo.beverageTotal)),
          _buildInfoRow('Room Rental', _formatMoney(beo.roomRental)),
          _buildInfoRow('Equipment', _formatMoney(beo.equipmentRental)),
          _buildInfoRow(
              'Service Charge', _formatMoney(beo.serviceChargeAmount)),
          _buildInfoRow('Tax', _formatMoney(beo.taxAmount)),
          _buildInfoRow('Gratuity', _formatMoney(beo.gratuityAmount)),
          pw.SizedBox(height: 8),
          _buildTotalRow('Grand Total', _formatMoney(beo.displayTotal)),
        ]),

      // Menu
      if (beo.hasMenu)
        _buildSection('Menu', [
          if (beo.menuItems != null)
            pw.Text(beo.menuItems!, style: const pw.TextStyle(fontSize: 10)),
          if (beo.menuDetails != null) _buildJsonDetails(beo.menuDetails!),
        ]),

      // Beverages
      if (beo.beverageDetails != null)
        _buildSection('Beverages', [
          if (beo.beverageDetails != null)
            _buildJsonDetails(beo.beverageDetails!),
        ]),

      // Setup
      if (beo.hasSetup)
        _buildSection('Room Setup', [
          _buildInfoRow('Menu Style', beo.menuStyle),
          if (beo.setupDetails != null) _buildJsonDetails(beo.setupDetails!),
        ]),

      // Staffing
      if (beo.hasStaffing)
        _buildSection('Staffing', [
          if (beo.staffingRequirements != null)
            pw.Text(beo.staffingRequirements!,
                style: const pw.TextStyle(fontSize: 10)),
          if (beo.staffingDetails != null)
            _buildJsonDetails(beo.staffingDetails!),
        ]),

      // Vendors
      if (beo.hasVendors)
        _buildSection('Vendors', [
          if (beo.vendorDetails != null) _buildVendorTable(beo.vendorDetails!),
        ]),

      // Notes
      if (beo.specialRequests != null && beo.specialRequests!.isNotEmpty)
        _buildSection('Special Requests & Notes', [
          pw.Text(beo.specialRequests!,
              style: const pw.TextStyle(fontSize: 10)),
        ]),

      // Timeline
      if (beo.hasTimeline)
        _buildSection('Event Timeline', [
          if (beo.eventTimeline != null) _buildTimeline(beo.eventTimeline!),
        ]),
    ];
  }

  /// Build a section with title and content
  pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  content.where((w) => w != pw.SizedBox.shrink()).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build an info row with label and value
  pw.Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  /// Build a total row (bold)
  pw.Widget _buildTotalRow(String label, String? value) {
    if (value == null || value.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Format money value
  String? _formatMoney(double? value) {
    if (value == null || value == 0) return null;
    return _currencyFormat.format(value);
  }

  /// Build content from JSON details
  pw.Widget _buildJsonDetails(Map<String, dynamic> details) {
    final widgets = <pw.Widget>[];

    for (final entry in details.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        if (entry.value is List) {
          widgets.add(pw.Text(
            '${_formatKey(entry.key)}:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ));
          for (final item in entry.value as List) {
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12),
              child: pw.Text('• $item', style: const pw.TextStyle(fontSize: 9)),
            ));
          }
        } else if (entry.value is Map) {
          widgets.add(pw.Text(
            '${_formatKey(entry.key)}:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ));
          for (final subEntry in (entry.value as Map).entries) {
            widgets.add(_buildInfoRow(_formatKey(subEntry.key.toString()),
                subEntry.value?.toString()));
          }
        } else {
          widgets.add(
              _buildInfoRow(_formatKey(entry.key), entry.value.toString()));
        }
      }
    }

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  /// Build vendor table
  pw.Widget _buildVendorTable(List<dynamic> vendors) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Vendor', isHeader: true),
            _tableCell('Type', isHeader: true),
            _tableCell('Contact', isHeader: true),
          ],
        ),
        // Data rows
        ...vendors.map((vendor) {
          final v = vendor as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              _tableCell(v['name'] ?? ''),
              _tableCell(v['type'] ?? ''),
              _tableCell(v['phone'] ?? v['email'] ?? ''),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build timeline
  pw.Widget _buildTimeline(List<dynamic> timeline) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Time', isHeader: true),
            _tableCell('Activity', isHeader: true),
          ],
        ),
        ...timeline.map((item) {
          final i = item as Map<String, dynamic>;
          return pw.TableRow(
            children: [
              _tableCell(i['time'] ?? ''),
              _tableCell(i['activity'] ?? i['description'] ?? ''),
            ],
          );
        }),
      ],
    );
  }

  /// Format key from snake_case to Title Case
  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
