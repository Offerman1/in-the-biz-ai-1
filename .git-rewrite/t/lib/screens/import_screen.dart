import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../providers/shift_provider.dart';
import '../theme/app_theme.dart';
import '../models/shift.dart';
import 'dashboard_screen.dart';

class ImportScreen extends StatefulWidget {
  final bool isFirstImport;

  const ImportScreen({super.key, this.isFirstImport = false});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _headers = [];
  List<List<dynamic>> _allRows = [];
  Map<String, dynamic>? _aiAnalysis;
  int _currentStep = 0; // 0 = upload, 1 = preview, 2 = importing, 3 = success
  String? _preSelectedJobId; // User can pre-select job before import
  List<Map<String, dynamic>> _existingJobs = []; // User's existing jobs

  @override
  void initState() {
    super.initState();
    _loadExistingJobs();
    _checkImportEligibility();
  }

  Future<void> _loadExistingJobs() async {
    try {
      final db = DatabaseService();
      final jobs = await db.getJobs();
      setState(() {
        _existingJobs = jobs;
      });
    } catch (e) {
      print('Failed to load existing jobs: $e');
    }
  }

  Future<void> _checkImportEligibility() async {
    // Check if this is NOT the first import (coming from settings)
    if (!widget.isFirstImport) {
      final importCount = await _getImportCount();

      if (importCount > 0) {
        // User has imported before - check if they're Pro
        final isPro = await _checkProStatus();

        if (!isPro) {
          // Free user, 2nd+ import - show ad
          final adWatched = await _showImportAd();
          if (!adWatched) {
            // User didn't watch ad - go back
            if (mounted) {
              Navigator.pop(context);
            }
            return;
          }
        }
      }
    }
  }

  Future<int> _getImportCount() async {
    try {
      final db = DatabaseService();
      return await db.getImportCount();
    } catch (e) {
      return 0;
    }
  }

  Future<bool> _checkProStatus() async {
    // TODO: Implement Pro status check
    // For now, return false (all users are free tier)
    return false;
  }

  Future<bool> _showImportAd() async {
    // TODO: Implement Google AdMob rewarded video ad
    // For now, show a dialog explaining the feature
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Watch Ad to Import', style: AppTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library, size: 48, color: AppTheme.accentBlue),
            const SizedBox(height: 16),
            Text(
              'Watch a 15-second ad to import more data',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.star, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Upgrade to Pro for unlimited imports',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.primaryGreen),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Show actual AdMob ad here
              // For now, simulate ad watched
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes!;

      // Parse file based on extension
      if (file.extension == 'csv') {
        await _parseCSV(bytes);
      } else {
        await _parseExcel(bytes);
      }

      if (_headers.isNotEmpty && _allRows.isNotEmpty) {
        await _analyzeWithAI();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to read file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _parseCSV(Uint8List bytes) async {
    final csvString = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }

    setState(() {
      _headers = rows[0].map((e) => e.toString()).toList();
      _allRows = rows.skip(1).toList();
    });
  }

  Future<void> _parseExcel(Uint8List bytes) async {
    final excelFile = excel_pkg.Excel.decodeBytes(bytes);
    final sheet = excelFile.tables.values.first;

    if (sheet.rows.isEmpty) {
      throw Exception('Excel file is empty');
    }

    setState(() {
      _headers =
          sheet.rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
      _allRows = sheet.rows
          .skip(1)
          .map((row) => row.map((cell) => cell?.value).toList())
          .toList();
    });
  }

  Future<void> _analyzeWithAI() async {
    try {
      // Take first 10 rows as samples for better job detection
      final sampleRows = _allRows.take(10).map((row) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < _headers.length && i < row.length; i++) {
          rowMap[_headers[i]] = row[i];
        }
        return rowMap;
      }).toList();

      final analysis = await ApiService.analyzeImport(
        headers: _headers,
        sampleRows: sampleRows,
        preSelectedJobId: _preSelectedJobId,
        existingJobs: _existingJobs,
      );

      setState(() {
        _aiAnalysis = analysis;
        _isLoading = false;
      });

      // Check if AI found too many jobs (likely party names instead)
      final detectedJobs = _aiAnalysis!['detected_jobs'] as List?;
      if (detectedJobs != null && detectedJobs.length > 10) {
        await _showTooManyJobsDialog(detectedJobs);
      }

      // Check for ambiguous mappings that need user input
      await _resolveAmbiguousMappings();

      setState(() {
        _currentStep = 1;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'AI analysis failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _performImport() async {
    if (_aiAnalysis == null) return;

    setState(() {
      _isLoading = true;
      _currentStep = 2;
      _errorMessage = null;
    });

    try {
      final mappings = _aiAnalysis!['mappings'] as Map<String, dynamic>;
      final db = DatabaseService();
      int successCount = 0;
      int failCount = 0;
      final List<String> errors = [];

      for (int rowIndex = 0; rowIndex < _allRows.length; rowIndex++) {
        try {
          final row = _allRows[rowIndex];
          final Map<String, dynamic> shiftData = {};

          // Map each column to our shift fields
          for (int i = 0; i < _headers.length && i < row.length; i++) {
            final header = _headers[i];
            final mapping = mappings[header];

            if (mapping != null && mapping['maps_to'] != 'unmapped') {
              final fieldName = mapping['maps_to'];
              shiftData[fieldName] = row[i];
            }
          }

          // Validate required fields
          if (!shiftData.containsKey('date') || shiftData['date'] == null) {
            throw Exception('Missing date');
          }

          // Parse date
          final dateStr = shiftData['date'].toString();
          DateTime? shiftDate;
          try {
            shiftDate = DateTime.parse(dateStr);
          } catch (e) {
            // Try parsing with detected format
            // Simple date parsing (can be enhanced)
            shiftDate = DateTime.tryParse(dateStr);
          }

          if (shiftDate == null) {
            throw Exception('Invalid date format');
          }

          // Create shift object
          final shift = Shift(
            id: '', // Will be generated
            date: shiftDate,
            jobId: shiftData['job_name']?.toString(),
            hourlyRate: _parseDouble(shiftData['hourly_rate']) ?? 0.0,
            hoursWorked: _parseDouble(shiftData['hours_worked']) ?? 0.0,
            cashTips: _parseDouble(shiftData['cash_tips']) ?? 0.0,
            creditTips: _parseDouble(shiftData['credit_tips']) ?? 0.0,
            startTime: shiftData['start_time']?.toString(),
            endTime: shiftData['end_time']?.toString(),
            notes: shiftData['notes']?.toString(),
            eventName: shiftData['event_name']?.toString(),
            location: shiftData['location']?.toString(),
            commission: _parseDouble(shiftData['commission']),
            mileage: _parseDouble(shiftData['mileage']),
            salesAmount: _parseDouble(shiftData['sales_amount']),
            tipoutPercent: _parseDouble(shiftData['tipout_percent']),
            guestCount: _parseInt(shiftData['guest_count']),
            flatRate: _parseDouble(shiftData['flat_rate']),
            overtimeHours: _parseDouble(shiftData['overtime_hours']),
          );

          await db.createShift(shift);
          successCount++;
        } catch (e) {
          failCount++;
          errors.add('Row ${rowIndex + 1}: $e');
        }
      }

      // Log analytics
      await _logImportAnalytics(successCount, failCount);

      // Reload shifts
      if (mounted) {
        await Provider.of<ShiftProvider>(context, listen: false).loadShifts();
      }

      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $successCount shifts successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Import failed: $e';
        _isLoading = false;
        _currentStep = 1;
      });
    }
  }

  Future<void> _logImportAnalytics(int successCount, int failCount) async {
    try {
      final unmappedFields = _aiAnalysis!['unmapped_fields'] as List;
      await DatabaseService().logImportAnalytics(
        totalRows: _allRows.length,
        successfulImports: successCount,
        failedRows: failCount,
        unmappedFields:
            unmappedFields.map((f) => f['column'].toString()).toList(),
        fieldSamples: Map.fromEntries(
          unmappedFields.map((f) => MapEntry(
                f['column'].toString(),
                f['samples'],
              )),
        ),
        fileHeaders: _headers,
        confidenceScore:
            (_aiAnalysis!['overall_confidence'] as num?)?.toDouble(),
        warnings: (_aiAnalysis!['warnings'] as List?)
            ?.map((w) => w.toString())
            .toList(),
      );
    } catch (e) {
      print('Failed to log import analytics: $e');
    }
  }

  /// Check for ambiguous mappings and ask user to resolve them
  Future<void> _resolveAmbiguousMappings() async {
    if (_aiAnalysis == null || !mounted) return;

    final mappings = _aiAnalysis!['mappings'] as Map<String, dynamic>;
    final detectedJobName = _aiAnalysis!['detected_job_name'] as String?;

    // Check for low-confidence mappings or those with user_suggestions
    for (final entry in mappings.entries) {
      final columnName = entry.key;
      final mapping = entry.value as Map<String, dynamic>;
      final confidence = (mapping['confidence'] as num?)?.toDouble() ?? 0;
      final suggestions = mapping['user_suggestions'] as List?;

      // If confidence is low or there are suggestions, ask user
      if (confidence < 80 || (suggestions != null && suggestions.isNotEmpty)) {
        final resolved = await _showMappingDialog(
          columnName: columnName,
          currentMapping: mapping['maps_to'] as String,
          suggestions: suggestions?.cast<Map<String, dynamic>>() ?? [],
          samples: _allRows
              .take(3)
              .map((row) {
                final index = _headers.indexOf(columnName);
                return index >= 0 && index < row.length ? row[index] : null;
              })
              .where((v) => v != null)
              .toList(),
        );

        if (resolved != null && mounted) {
          setState(() {
            mappings[columnName]['maps_to'] = resolved;
            mappings[columnName]['confidence'] = 100.0;
          });
        }
      }
    }

    // If there's a detected job name and job_name field is mapped, ask about it
    if (detectedJobName != null && detectedJobName.isNotEmpty) {
      final jobNameColumn = mappings.entries
          .firstWhere(
            (e) => (e.value as Map)['maps_to'] == 'job_name',
            orElse: () => const MapEntry('', {}),
          )
          .key;

      if (jobNameColumn.isNotEmpty && mounted) {
        await _showJobNameDialog(detectedJobName, jobNameColumn);
      }
    }
  }

  /// Show dialog for ambiguous field mapping
  Future<String?> _showMappingDialog({
    required String columnName,
    required String currentMapping,
    required List<Map<String, dynamic>> suggestions,
    required List<dynamic> samples,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.accentBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'How should we map "$columnName"?',
                style: AppTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sample values from your file:',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: samples.take(3).map((sample) {
                    return Text(
                      '• ${sample.toString()}',
                      style:
                          AppTheme.labelSmall.copyWith(fontFamily: 'monospace'),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose where this data should go:',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ...suggestions.map((suggestion) {
                final field = suggestion['field'] as String;
                final reason = suggestion['reason'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, field),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field == 'unmapped'
                                  ? 'Skip this field'
                                  : field.replaceAll('_', ' ').toUpperCase(),
                              style: AppTheme.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reason,
                              style: AppTheme.labelSmall
                                  .copyWith(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog for detected job name
  Future<void> _showJobNameDialog(
      String detectedJobName, String columnName) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(Icons.work_outline, color: AppTheme.accentBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Job Name Detected',
                style: AppTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'I found the job name:',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    detectedJobName,
                    style: AppTheme.titleMedium
                        .copyWith(color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to do?',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'use_existing'),
            child: Text('Use Existing Job',
                style: TextStyle(color: AppTheme.adaptiveTextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'create_new'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create New Job'),
          ),
        ],
      ),
    );

    if (result == 'create_new' && mounted) {
      await _showCreateJobDialog(detectedJobName);
    }
  }

  /// Show dialog to create new job
  Future<void> _showCreateJobDialog(String suggestedName) async {
    final controller = TextEditingController(text: suggestedName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Create New Job', style: AppTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Job Name',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.adaptiveTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final jobName = controller.text.trim();
              if (jobName.isNotEmpty) {
                // Create job in database
                try {
                  // TODO: Create job with proper structure
                  // For now, just close dialog
                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Job "$jobName" will be created'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create job: $e'),
                        backgroundColor: AppTheme.accentRed,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when AI detects >10 jobs (likely party names)
  Future<void> _showTooManyJobsDialog(List<dynamic> detectedJobs) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.accentOrange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Too Many Jobs Detected',
                style:
                    AppTheme.titleMedium.copyWith(color: AppTheme.accentOrange),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I found ${detectedJobs.length} different "job" names in your file, but most users only have 1-5 jobs (employers).',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Sample values:',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: detectedJobs.take(5).map((job) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${job.toString()}',
                        style: AppTheme.labelSmall
                            .copyWith(fontFamily: 'monospace'),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (detectedJobs.length > 5) ...[
                const SizedBox(height: 4),
                Text(
                  '...and ${detectedJobs.length - 5} more',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Are these actually event/party names instead of employer names?',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Remap these as event names instead
              if (_aiAnalysis != null) {
                final mappings =
                    _aiAnalysis!['mappings'] as Map<String, dynamic>;
                for (final entry in mappings.entries) {
                  final mapping = entry.value as Map<String, dynamic>;
                  if (mapping['maps_to'] == 'job_name') {
                    mapping['maps_to'] = 'event_name';
                  }
                }
              }
              Navigator.pop(context);
            },
            child: Text('Yes, Treat as Event Names',
                style: TextStyle(color: AppTheme.adaptiveTextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('No, Keep as Jobs'),
          ),
        ],
      ),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove ALL currency symbols (USD, EUR, GBP, JPY, etc.), commas, and whitespace
      final cleaned = value
          .replaceAll(RegExp(r'[\$€£¥₹₽₩₪₱₦₡₨₴₵₸₹¢]'), '') // Currency symbols
          .replaceAll(',', '') // Thousands separator
          .trim();
      return double.tryParse(cleaned);
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[,\s]'), '').trim();
      return int.tryParse(cleaned);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Shifts',
            style: AppTheme.titleLarge
                .copyWith(color: AppTheme.adaptiveTextColor)),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_currentStep == 0) {
      return _buildUploadScreen();
    } else if (_currentStep == 1) {
      return _buildPreviewScreen();
    } else if (_currentStep == 2) {
      return _buildImportingScreen();
    } else {
      return _buildSuccessScreen();
    }
  }

  Widget _buildUploadScreen() {
    return Center(
      child: _isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                const SizedBox(height: 24),
                Text(
                  'Analyzing your data...',
                  style: AppTheme.bodyLarge
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 80,
                    color: AppTheme.primaryGreen.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Import Your Shift Data',
                    style: AppTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload a CSV or Excel file from your old tip tracking app.\nWe\'ll automatically map your data in seconds!',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Job selection (optional)
                  if (_existingJobs.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.work_outline,
                                  color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Assign to Job (Optional)',
                                style: AppTheme.titleMedium
                                    .copyWith(color: AppTheme.primaryGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'If all shifts are from the same job, select it here:',
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // "Auto-detect" option
                              ChoiceChip(
                                label: const Text('Auto-detect'),
                                selected: _preSelectedJobId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _preSelectedJobId = null);
                                  }
                                },
                                selectedColor: AppTheme.primaryGreen,
                                backgroundColor: AppTheme.darkBackground,
                                labelStyle: TextStyle(
                                  color: _preSelectedJobId == null
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                              ),
                              // Job options
                              ..._existingJobs.map((job) {
                                final jobId = job['id']?.toString() ?? '';
                                final jobName =
                                    job['title']?.toString() ?? 'Unknown Job';
                                if (jobId.isEmpty)
                                  return const SizedBox.shrink();
                                return ChoiceChip(
                                  label: Text(jobName),
                                  selected: _preSelectedJobId == jobId,
                                  onSelected: (selected) {
                                    setState(() {
                                      _preSelectedJobId =
                                          selected ? jobId : null;
                                    });
                                  },
                                  selectedColor: AppTheme.primaryGreen,
                                  backgroundColor: AppTheme.darkBackground,
                                  labelStyle: TextStyle(
                                    color: _preSelectedJobId == jobId
                                        ? Colors.white
                                        : AppTheme.textMuted,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Choose File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.accentRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.accentRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTheme.bodyMedium
                                  .copyWith(color: AppTheme.accentRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewScreen() {
    if (_aiAnalysis == null) return const SizedBox();

    final mappings = _aiAnalysis!['mappings'] as Map<String, dynamic>;
    final overallConfidence =
        (_aiAnalysis!['overall_confidence'] as num?)?.toDouble() ?? 0;
    final warnings = (_aiAnalysis!['warnings'] as List?)?.cast<String>() ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            24, 24, 24, 120), // Extra bottom padding for buttons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getConfidenceColor(overallConfidence).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _getConfidenceColor(overallConfidence).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getConfidenceIcon(overallConfidence),
                    color: _getConfidenceColor(overallConfidence),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Complete',
                          style: AppTheme.titleMedium.copyWith(
                            color: _getConfidenceColor(overallConfidence),
                          ),
                        ),
                        Text(
                          '${overallConfidence.toInt()}% confidence • ${_allRows.length} shifts found',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Warnings
            if (warnings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.accentOrange),
                        const SizedBox(width: 8),
                        Text('Warnings', style: AppTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• $w', style: AppTheme.labelSmall),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Column mappings
            Text('Column Mappings', style: AppTheme.titleMedium),
            const SizedBox(height: 12),
            ...mappings.entries.map((entry) {
              final mapping = entry.value as Map<String, dynamic>;
              final confidence =
                  (mapping['confidence'] as num?)?.toDouble() ?? 0;
              final mapsTo = mapping['maps_to'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getConfidenceColor(confidence).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: AppTheme.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            mapsTo == 'unmapped' ? 'Not mapped' : '→ $mapsTo',
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${confidence.toInt()}%',
                      style: AppTheme.labelSmall.copyWith(
                        color: _getConfidenceColor(confidence),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _aiAnalysis = null;
                        _headers = [];
                        _allRows = [];
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _performImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Import ${_allRows.length} Shifts'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 24),
          Text(
            'Importing your shifts...',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Import Complete!',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Successfully imported ${_allRows.length} shifts',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (widget.isFirstImport) {
                  // Coming from onboarding - go to dashboard
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                } else {
                  // Coming from settings - go back
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) return AppTheme.primaryGreen;
    if (confidence >= 70) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 90) return Icons.check_circle;
    if (confidence >= 70) return Icons.warning_amber;
    return Icons.error_outline;
  }
}
