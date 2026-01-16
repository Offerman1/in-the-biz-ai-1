import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/shift.dart';

/// Export Service for generating CSV and PDF reports
class ExportService {
  // Brand colors for PDF
  static const PdfColor _primaryGreen = PdfColor.fromInt(0xFF00D632);
  static const PdfColor _accentBlue = PdfColor.fromInt(0xFF00A3FF);
  static const PdfColor _accentOrange = PdfColor.fromInt(0xFFFF9500);
  static const PdfColor _accentPurple = PdfColor.fromInt(0xFF9B59B6);

  /// Helper to get job name from jobs list
  static String _getJobName(Shift shift, List<Map<String, dynamic>>? jobs) {
    if (jobs == null || jobs.isEmpty || shift.jobId == null) {
      return shift.jobType ?? 'General';
    }
    try {
      final job = jobs.firstWhere(
        (j) => j['id'] == shift.jobId,
        orElse: () => <String, dynamic>{},
      );
      return job['name'] ?? job['title'] ?? shift.jobType ?? 'General';
    } catch (e) {
      return shift.jobType ?? 'General';
    }
  }

  /// Export shifts to CSV file and return file path
  static Future<String> exportToCSV({
    required List<dynamic> shifts,
    required DateTime startDate,
    required DateTime endDate,
    List<Map<String, dynamic>>? jobs,
  }) async {
    final shiftList = shifts.cast<Shift>();
    final filteredShifts = shiftList
        .where((s) =>
            s.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            s.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final csv = generateSummaryCSV(
      shifts: filteredShifts,
      startDate: startDate,
      endDate: endDate,
      jobs: jobs,
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'shifts_${DateFormat('yyyy-MM').format(startDate)}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }

  /// Export shifts to professional multi-page PDF report
  static Future<String> exportToPDF({
    required List<dynamic> shifts,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
    List<Map<String, dynamic>>? jobs,
  }) async {
    final shiftList = shifts.cast<Shift>();
    final filteredShifts = shiftList
        .where((s) =>
            s.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            s.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending

    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM yyyy');
    final currencyFormat = NumberFormat.simpleCurrency();

    // Calculate all statistics
    final stats = _calculateStats(filteredShifts, shiftList, jobs);

    // ==================== PAGE 1: EXECUTIVE SUMMARY ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(dateFormat.format(startDate)),
            pw.SizedBox(height: 30),

            // Main stats row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total Income',
                    currencyFormat.format(stats['totalIncome']), _primaryGreen),
                _buildStatCard('Total Hours',
                    stats['totalHours'].toStringAsFixed(1), _accentBlue),
                _buildStatCard('Avg Hourly',
                    currencyFormat.format(stats['avgHourly']), _accentOrange),
              ],
            ),
            pw.SizedBox(height: 20),

            // Secondary stats row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                    'Shifts', '${stats['shiftCount']}', PdfColors.grey600),
                _buildStatCard('Total Tips',
                    currencyFormat.format(stats['totalTips']), _primaryGreen),
                _buildStatCard('Total Wages',
                    currencyFormat.format(stats['totalWages']), _accentBlue),
              ],
            ),
            pw.SizedBox(height: 30),

            // Month comparison
            if (stats['previousMonthTotal'] > 0) ...[
              _buildComparisonSection(stats, currencyFormat),
              pw.SizedBox(height: 30),
            ],

            // Quick summary box
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('QUICK SUMMARY',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800)),
                  pw.SizedBox(height: 15),
                  _buildSummaryRow('Average Income per Shift',
                      currencyFormat.format(stats['avgPerShift'])),
                  _buildSummaryRow('Average Hours per Shift',
                      '${stats['avgHoursPerShift'].toStringAsFixed(1)} hrs'),
                  _buildSummaryRow('Shifts per Week',
                      stats['shiftsPerWeek'].toStringAsFixed(1)),
                  _buildSummaryRow('Cash Tips',
                      currencyFormat.format(stats['totalCashTips'])),
                  _buildSummaryRow('Credit Tips',
                      currencyFormat.format(stats['totalCreditTips'])),
                  pw.Divider(color: PdfColors.grey400),
                  _buildSummaryRow('Best Day', stats['bestDay'] ?? 'N/A',
                      isBold: true),
                  _buildSummaryRow('Best Day Avg',
                      currencyFormat.format(stats['bestDayAvg']),
                      isBold: true),
                ],
              ),
            ),

            pw.Spacer(),
            _buildFooter(1, 4),
          ],
        ),
      ),
    );

    // ==================== PAGE 2: INCOME BREAKDOWN ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('INCOME BREAKDOWN', _accentBlue),
            pw.SizedBox(height: 25),

            // Weekly earnings chart
            pw.Text('Weekly Earnings',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildWeeklyBarChart(
                stats['weeklyTotals'] as Map<int, double>, currencyFormat),
            pw.SizedBox(height: 30),

            // Tips breakdown
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TIPS ANALYSIS',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 15),
                      _buildTipsBreakdown(stats, currencyFormat),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INCOME SOURCES',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 15),
                      _buildIncomeSourcesBreakdown(stats, currencyFormat),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Job type breakdown if multiple jobs
            if ((stats['jobTypeTotals'] as Map).length > 1) ...[
              pw.Text('INCOME BY JOB TYPE',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700)),
              pw.SizedBox(height: 15),
              _buildJobTypeBreakdown(
                  stats['jobTypeTotals'] as Map<String, double>,
                  stats['totalIncome'] as double,
                  currencyFormat),
            ],

            pw.Spacer(),
            _buildFooter(2, 4),
          ],
        ),
      ),
    );

    // ==================== PAGE 3: PERFORMANCE METRICS ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('PERFORMANCE METRICS', _accentOrange),
            pw.SizedBox(height: 25),

            // Efficiency metrics
            pw.Row(
              children: [
                pw.Expanded(
                    child: _buildMetricBox(
                        'Effective Rate',
                        '${currencyFormat.format(stats['avgHourly'])}/hr',
                        _primaryGreen)),
                pw.SizedBox(width: 15),
                pw.Expanded(
                    child: _buildMetricBox(
                        'Avg per Shift',
                        currencyFormat.format(stats['avgPerShift']),
                        _accentBlue)),
                pw.SizedBox(width: 15),
                pw.Expanded(
                    child: _buildMetricBox(
                        'Shifts/Week',
                        stats['shiftsPerWeek'].toStringAsFixed(1),
                        _accentOrange)),
              ],
            ),
            pw.SizedBox(height: 30),

            // Best days
            pw.Text('BEST PERFORMING DAYS',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 15),
            _buildBestDaysTable(
                stats['dayAverages'] as Map<int, double>, currencyFormat),
            pw.SizedBox(height: 30),

            // 6-month trend
            pw.Text('6-MONTH INCOME TREND',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 15),
            _buildMonthlyTrendChart(
                stats['monthlyTotals'] as Map<String, double>, currencyFormat),

            pw.Spacer(),
            _buildFooter(3, 4),
          ],
        ),
      ),
    );

    // ==================== PAGE 4+: DETAILED SHIFT LOG ====================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) {
          // Show "continued" only on pages after page 4 (first shift details page)
          if (context.pageNumber > 4) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text('SHIFT DETAILS (continued)',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            );
          }
          return pw.Container();
        },
        footer: (context) {
          // Just show the page number without total
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by In The Biz AI',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500)),
                pw.Text(DateFormat('MMMM d, yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500)),
                pw.Text('Page ${context.pageNumber}',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500)),
              ],
            ),
          );
        },
        build: (context) => [
          _buildSectionHeader('SHIFT DETAILS', _accentPurple),
          pw.SizedBox(height: 20),

          // Shifts table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF333333)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            headers: [
              'Date',
              'Job',
              'Hours',
              'Cash Tips',
              'Credit Tips',
              'Total'
            ],
            data: filteredShifts
                .map((s) => [
                      DateFormat('MM/dd/yy').format(s.date),
                      _getJobName(s, jobs),
                      s.hoursWorked.toStringAsFixed(1),
                      currencyFormat.format(s.cashTips),
                      currencyFormat.format(s.creditTips),
                      currencyFormat.format(s.totalIncome),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),

          // Totals row
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTALS: ${filteredShifts.length} shifts',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(currencyFormat.format(stats['totalIncome']),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'InTheBiz_Report_${DateFormat('yyyy-MM').format(startDate)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  // ==================== PDF HELPER WIDGETS ====================

  static pw.Widget _buildHeader(String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IN THE BIZ',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryGreen,
                    )),
                pw.Text('INCOME REPORT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                      letterSpacing: 2,
                    )),
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _primaryGreen,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(period,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  )),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 3, color: _primaryGreen),
      ],
    );
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            )),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, width: 60, color: color),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: color,
              )),
          pw.SizedBox(height: 5),
          pw.Text(label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 50,
          color: color,
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(label,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonSection(
      Map<String, dynamic> stats, NumberFormat currencyFormat) {
    final double current = stats['totalIncome'];
    final double previous = stats['previousMonthTotal'];
    final double diff = current - previous;
    final double percent = previous > 0 ? (diff / previous * 100) : 0;
    final bool isPositive = diff >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: isPositive
            ? const PdfColor.fromInt(0xFFE8F5E9)
            : const PdfColor.fromInt(0xFFFFEBEE),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 32,
            height: 32,
            decoration: pw.BoxDecoration(
              color: isPositive
                  ? _primaryGreen
                  : const PdfColor.fromInt(0xFFE53935),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                isPositive ? '+' : '-',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('vs Previous Month',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.Text(
                '${isPositive ? '+' : ''}${currencyFormat.format(diff)} (${percent.toStringAsFixed(1)}%)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: isPositive
                      ? _primaryGreen
                      : const PdfColor.fromInt(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWeeklyBarChart(
      Map<int, double> weeklyTotals, NumberFormat currencyFormat) {
    final maxValue = weeklyTotals.values.isEmpty
        ? 100.0
        : weeklyTotals.values.reduce(math.max);

    return pw.Container(
      height: 120,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) {
          final week = index + 1;
          final value = weeklyTotals[week] ?? 0;
          final height = maxValue > 0 ? (value / maxValue * 80) : 0.0;

          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(currencyFormat.format(value),
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: 50,
                height: height,
                decoration: pw.BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(4)),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Week $week', style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        }),
      ),
    );
  }

  static pw.Widget _buildTipsBreakdown(
      Map<String, dynamic> stats, NumberFormat currencyFormat) {
    final double cashTips = stats['totalCashTips'];
    final double creditTips = stats['totalCreditTips'];
    final double totalTips = cashTips + creditTips;
    final double cashPercent = totalTips > 0 ? (cashTips / totalTips * 100) : 0;
    final double creditPercent =
        totalTips > 0 ? (creditTips / totalTips * 100) : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildTipRow('Cash Tips', currencyFormat.format(cashTips),
              '${cashPercent.toStringAsFixed(0)}%', _primaryGreen),
          pw.SizedBox(height: 10),
          _buildTipRow('Credit Tips', currencyFormat.format(creditTips),
              '${creditPercent.toStringAsFixed(0)}%', _accentBlue),
          pw.Divider(color: PdfColors.grey400),
          _buildTipRow('Total Tips', currencyFormat.format(totalTips), '100%',
              PdfColors.grey800),
          pw.SizedBox(height: 10),
          pw.Text(
              'Avg Tips/Shift: ${currencyFormat.format(stats['avgTipsPerShift'])}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildTipRow(
      String label, String amount, String percent, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Container(width: 10, height: 10, color: color),
            pw.SizedBox(width: 8),
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Text('$amount ($percent)', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildIncomeSourcesBreakdown(
      Map<String, dynamic> stats, NumberFormat currencyFormat) {
    final double tips = stats['totalTips'];
    final double wages = stats['totalWages'];
    final double total = tips + wages;
    final double tipsPercent = total > 0 ? (tips / total * 100) : 0;
    final double wagesPercent = total > 0 ? (wages / total * 100) : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildTipRow('Tips', currencyFormat.format(tips),
              '${tipsPercent.toStringAsFixed(0)}%', _accentOrange),
          pw.SizedBox(height: 10),
          _buildTipRow('Wages', currencyFormat.format(wages),
              '${wagesPercent.toStringAsFixed(0)}%', _accentPurple),
          pw.Divider(color: PdfColors.grey400),
          _buildTipRow(
              'Total', currencyFormat.format(total), '100%', PdfColors.grey800),
        ],
      ),
    );
  }

  static pw.Widget _buildJobTypeBreakdown(Map<String, double> jobTotals,
      double total, NumberFormat currencyFormat) {
    final sortedJobs = jobTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      _primaryGreen,
      _accentBlue,
      _accentOrange,
      _accentPurple,
      PdfColors.grey600
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: sortedJobs.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final job = entry.value;
          final percent = total > 0 ? (job.value / total * 100) : 0;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: _buildTipRow(
                job.key,
                currencyFormat.format(job.value),
                '${percent.toStringAsFixed(0)}%',
                colors[index % colors.length]),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildBestDaysTable(
      Map<int, double> dayAverages, NumberFormat currencyFormat) {
    final dayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final sortedDays = dayAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: sortedDays.take(3).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final day = entry.value;
          final isFirst = rank == 1;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: pw.BoxDecoration(
                    color: isFirst ? _primaryGreen : PdfColors.grey400,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text('$rank',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                    child: pw.Text(dayNames[day.key],
                        style: const pw.TextStyle(fontSize: 11))),
                pw.Text(currencyFormat.format(day.value),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isFirst ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: isFirst ? _primaryGreen : PdfColors.grey800,
                    )),
                pw.Text(' avg',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildMonthlyTrendChart(
      Map<String, double> monthlyTotals, NumberFormat currencyFormat) {
    if (monthlyTotals.isEmpty) {
      return pw.Text('Not enough data for trend',
          style: const pw.TextStyle(color: PdfColors.grey600));
    }

    final sortedMonths = monthlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last6 = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;
    final maxValue = last6.map((e) => e.value).reduce(math.max);

    return pw.Container(
      height: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: last6.map((entry) {
          final height = maxValue > 0 ? (entry.value / maxValue * 100) : 0.0;
          final monthName =
              DateFormat('MMM').format(DateTime.parse('${entry.key}-01'));

          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(currencyFormat.format(entry.value),
                  style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: 35,
                height: height,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_primaryGreen, _accentBlue],
                    begin: pw.Alignment.bottomCenter,
                    end: pw.Alignment.topCenter,
                  ),
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(4)),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(monthName, style: const pw.TextStyle(fontSize: 9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildFooter(int pageNum, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by In The Biz AI',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          pw.Text(DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          pw.Text('Page $pageNum',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ==================== STATS CALCULATION ====================

  static Map<String, dynamic> _calculateStats(List<Shift> filteredShifts,
      List<Shift> allShifts, List<Map<String, dynamic>>? jobs) {
    // Basic totals
    double totalCashTips = 0;
    double totalCreditTips = 0;
    double totalHours = 0;
    double totalWages = 0;

    for (final shift in filteredShifts) {
      totalCashTips += shift.cashTips;
      totalCreditTips += shift.creditTips;
      totalHours += shift.hoursWorked;
      totalWages += shift.hourlyRate * shift.hoursWorked;
    }

    final totalTips = totalCashTips + totalCreditTips;
    final totalIncome = totalTips + totalWages;
    final avgHourly = totalHours > 0 ? totalIncome / totalHours : 0.0;
    final avgPerShift =
        filteredShifts.isNotEmpty ? totalIncome / filteredShifts.length : 0.0;
    final avgHoursPerShift =
        filteredShifts.isNotEmpty ? totalHours / filteredShifts.length : 0.0;
    final avgTipsPerShift =
        filteredShifts.isNotEmpty ? totalTips / filteredShifts.length : 0.0;

    // Calculate weeks in period
    final weeks = filteredShifts.isNotEmpty
        ? (filteredShifts.first.date
                    .difference(filteredShifts.last.date)
                    .inDays
                    .abs() /
                7)
            .ceil()
        : 1;
    final shiftsPerWeek = weeks > 0 ? filteredShifts.length / weeks : 0.0;

    // Weekly totals
    final weeklyTotals = <int, double>{};
    for (final shift in filteredShifts) {
      final week = ((shift.date.day - 1) ~/ 7) + 1;
      weeklyTotals[week] = (weeklyTotals[week] ?? 0) + shift.totalIncome;
    }

    // Day averages
    final dayTotals = <int, List<double>>{};
    for (final shift in filteredShifts) {
      dayTotals
          .putIfAbsent(shift.date.weekday, () => [])
          .add(shift.totalIncome);
    }
    final dayAverages = dayTotals.map((key, value) =>
        MapEntry(key, value.fold(0.0, (a, b) => a + b) / value.length));

    // Best day
    String? bestDay;
    double bestDayAvg = 0;
    if (dayAverages.isNotEmpty) {
      final sortedDays = dayAverages.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final dayNames = [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      bestDay = dayNames[sortedDays.first.key];
      bestDayAvg = sortedDays.first.value;
    }

    // Job type totals (use actual job names from jobs list)
    final jobTypeTotals = <String, double>{};
    for (final shift in filteredShifts) {
      final jobName = _getJobName(shift, jobs);
      jobTypeTotals[jobName] =
          (jobTypeTotals[jobName] ?? 0) + shift.totalIncome;
    }

    // Monthly totals (for trend)
    final monthlyTotals = <String, double>{};
    for (final shift in allShifts) {
      final monthKey = DateFormat('yyyy-MM').format(shift.date);
      monthlyTotals[monthKey] =
          (monthlyTotals[monthKey] ?? 0) + shift.totalIncome;
    }

    // Previous month comparison
    double previousMonthTotal = 0;
    if (filteredShifts.isNotEmpty) {
      final currentMonth = filteredShifts.first.date;
      final prevMonthKey = DateFormat('yyyy-MM')
          .format(DateTime(currentMonth.year, currentMonth.month - 1));
      previousMonthTotal = monthlyTotals[prevMonthKey] ?? 0;
    }

    return {
      'shiftCount': filteredShifts.length,
      'totalHours': totalHours,
      'totalCashTips': totalCashTips,
      'totalCreditTips': totalCreditTips,
      'totalTips': totalTips,
      'totalWages': totalWages,
      'totalIncome': totalIncome,
      'avgHourly': avgHourly,
      'avgPerShift': avgPerShift,
      'avgHoursPerShift': avgHoursPerShift,
      'avgTipsPerShift': avgTipsPerShift,
      'shiftsPerWeek': shiftsPerWeek,
      'weeklyTotals': weeklyTotals,
      'dayAverages': dayAverages,
      'bestDay': bestDay,
      'bestDayAvg': bestDayAvg,
      'jobTypeTotals': jobTypeTotals,
      'monthlyTotals': monthlyTotals,
      'previousMonthTotal': previousMonthTotal,
    };
  }

  /// Generate CSV string from shifts data
  static String generateShiftsCSV(List<Shift> shifts,
      {List<Map<String, dynamic>>? jobs}) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
        'Date,Job,Hours Worked,Hourly Rate,Cash Tips,Credit Tips,Total Tips,Total Income,Event Name,Notes');

    // Data rows
    for (final shift in shifts) {
      final date = DateFormat('yyyy-MM-dd').format(shift.date);
      final jobName = _escapeCSV(_getJobName(shift, jobs));
      final hoursWorked = shift.hoursWorked.toStringAsFixed(2);
      final hourlyRate = shift.hourlyRate.toStringAsFixed(2);
      final cashTips = shift.cashTips.toStringAsFixed(2);
      final creditTips = shift.creditTips.toStringAsFixed(2);
      final totalTips = shift.totalTips.toStringAsFixed(2);
      final totalIncome = shift.totalIncome.toStringAsFixed(2);
      final eventName = _escapeCSV(shift.eventName ?? '');
      final notes = _escapeCSV(shift.notes ?? '');

      buffer.writeln(
          '$date,$jobName,$hoursWorked,$hourlyRate,$cashTips,$creditTips,$totalTips,$totalIncome,$eventName,$notes');
    }

    return buffer.toString();
  }

  /// Generate summary CSV with totals
  static String generateSummaryCSV({
    required List<Shift> shifts,
    required DateTime startDate,
    required DateTime endDate,
    List<Map<String, dynamic>>? jobs,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Summary header
    buffer.writeln('In The Biz AI - Income Report');
    buffer.writeln(
        'Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}');
    buffer.writeln('');

    // Calculate totals
    double totalCashTips = 0;
    double totalCreditTips = 0;
    double totalHours = 0;
    double totalWages = 0;

    for (final shift in shifts) {
      totalCashTips += shift.cashTips;
      totalCreditTips += shift.creditTips;
      totalHours += shift.hoursWorked;
      totalWages += shift.hourlyRate * shift.hoursWorked;
    }

    final totalTips = totalCashTips + totalCreditTips;
    final totalIncome = totalTips + totalWages;
    final avgHourly = totalHours > 0 ? totalIncome / totalHours : 0;

    // Summary section
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Shifts,${shifts.length}');
    buffer.writeln('Total Hours,${totalHours.toStringAsFixed(1)}');
    buffer.writeln('Total Cash Tips,\$${totalCashTips.toStringAsFixed(2)}');
    buffer.writeln('Total Credit Tips,\$${totalCreditTips.toStringAsFixed(2)}');
    buffer.writeln('Total Tips,\$${totalTips.toStringAsFixed(2)}');
    buffer.writeln('Total Wages,\$${totalWages.toStringAsFixed(2)}');
    buffer.writeln('Total Income,\$${totalIncome.toStringAsFixed(2)}');
    buffer.writeln(
        'Average Hourly (incl. tips),\$${avgHourly.toStringAsFixed(2)}');
    buffer.writeln('');

    // Detailed shifts
    buffer.writeln('DETAILED SHIFTS');
    buffer.write(generateShiftsCSV(shifts, jobs: jobs));

    return buffer.toString();
  }

  /// Generate JSON export of shifts
  static String generateShiftsJSON(List<Shift> shifts) {
    final data = shifts.map((s) => s.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toIso8601String(),
      'shift_count': shifts.length,
      'shifts': data,
    });
  }

  /// Group shifts by week and calculate totals
  static Map<String, WeeklySummary> getWeeklySummaries(List<Shift> shifts) {
    final summaries = <String, WeeklySummary>{};

    for (final shift in shifts) {
      // Get week start (Monday)
      final weekStart =
          shift.date.subtract(Duration(days: shift.date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      if (!summaries.containsKey(weekKey)) {
        summaries[weekKey] = WeeklySummary(weekStart: weekStart);
      }

      summaries[weekKey]!.addShift(shift);
    }

    return summaries;
  }

  /// Group shifts by month and calculate totals
  static Map<String, MonthlySummary> getMonthlySummaries(List<Shift> shifts) {
    final summaries = <String, MonthlySummary>{};

    for (final shift in shifts) {
      final monthKey = DateFormat('yyyy-MM').format(shift.date);

      if (!summaries.containsKey(monthKey)) {
        summaries[monthKey] = MonthlySummary(
          year: shift.date.year,
          month: shift.date.month,
        );
      }

      summaries[monthKey]!.addShift(shift);
    }

    return summaries;
  }

  /// Escape CSV special characters
  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class WeeklySummary {
  final DateTime weekStart;
  final List<Shift> shifts = [];

  WeeklySummary({required this.weekStart});

  void addShift(Shift shift) => shifts.add(shift);

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));
  int get shiftCount => shifts.length;
  double get totalHours => shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);
  double get totalTips => shifts.fold(0.0, (sum, s) => sum + s.totalTips);
  double get totalIncome => shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
  double get avgHourly => totalHours > 0 ? totalIncome / totalHours : 0;
}

class MonthlySummary {
  final int year;
  final int month;
  final List<Shift> shifts = [];

  MonthlySummary({required this.year, required this.month});

  void addShift(Shift shift) => shifts.add(shift);

  String get monthName => DateFormat('MMMM yyyy').format(DateTime(year, month));
  int get shiftCount => shifts.length;
  double get totalHours => shifts.fold(0.0, (sum, s) => sum + s.hoursWorked);
  double get totalCashTips => shifts.fold(0.0, (sum, s) => sum + s.cashTips);
  double get totalCreditTips =>
      shifts.fold(0.0, (sum, s) => sum + s.creditTips);
  double get totalTips => totalCashTips + totalCreditTips;
  double get totalWages =>
      shifts.fold(0.0, (sum, s) => sum + s.hourlyRate * s.hoursWorked);
  double get totalIncome => totalTips + totalWages;
  double get avgHourly => totalHours > 0 ? totalIncome / totalHours : 0;
}
