import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/shift.dart';

/// Export Service for generating CSV and PDF reports
class ExportService {
  /// Export shifts to CSV file and return file path
  static Future<String> exportToCSV({
    required List<dynamic> shifts,
    required DateTime startDate,
    required DateTime endDate,
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
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'shifts_${DateFormat('yyyy-MM').format(startDate)}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }

  /// Export shifts to PDF file and return file path
  static Future<String> exportToPDF({
    required List<dynamic> shifts,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) async {
    final shiftList = shifts.cast<Shift>();
    final filteredShifts = shiftList
        .where((s) =>
            s.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            s.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.simpleCurrency();

    // Calculate totals
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
    final avgHourly = totalHours > 0 ? totalIncome / totalHours : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title ?? 'In The Biz AI - Income Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Summary section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Shifts:'),
                    pw.Text('${filteredShifts.length}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Hours:'),
                    pw.Text(totalHours.toStringAsFixed(1)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cash Tips:'),
                    pw.Text(currencyFormat.format(totalCashTips)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Credit Tips:'),
                    pw.Text(currencyFormat.format(totalCreditTips)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Tips:'),
                    pw.Text(currencyFormat.format(totalTips)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Wages:'),
                    pw.Text(currencyFormat.format(totalWages)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Income:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(currencyFormat.format(totalIncome),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Avg Hourly (incl. tips):'),
                    pw.Text(currencyFormat.format(avgHourly)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Shifts table
          pw.Text('Shift Details',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
            headers: ['Date', 'Hours', 'Cash', 'Credit', 'Total'],
            data: filteredShifts
                .map((s) => [
                      DateFormat('MM/dd').format(s.date),
                      s.hoursWorked.toStringAsFixed(1),
                      currencyFormat.format(s.cashTips),
                      currencyFormat.format(s.creditTips),
                      currencyFormat.format(s.totalIncome),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'report_${DateFormat('yyyy-MM').format(startDate)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Generate CSV string from shifts data
  static String generateShiftsCSV(List<Shift> shifts) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
        'Date,Job Type,Hours Worked,Hourly Rate,Cash Tips,Credit Tips,Total Tips,Total Income,Event Name,Notes');

    // Data rows
    for (final shift in shifts) {
      final date = DateFormat('yyyy-MM-dd').format(shift.date);
      final jobType = _escapeCSV(shift.jobType ?? '');
      final hoursWorked = shift.hoursWorked.toStringAsFixed(2);
      final hourlyRate = shift.hourlyRate.toStringAsFixed(2);
      final cashTips = shift.cashTips.toStringAsFixed(2);
      final creditTips = shift.creditTips.toStringAsFixed(2);
      final totalTips = shift.totalTips.toStringAsFixed(2);
      final totalIncome = shift.totalIncome.toStringAsFixed(2);
      final eventName = _escapeCSV(shift.eventName ?? '');
      final notes = _escapeCSV(shift.notes ?? '');

      buffer.writeln(
          '$date,$jobType,$hoursWorked,$hourlyRate,$cashTips,$creditTips,$totalTips,$totalIncome,$eventName,$notes');
    }

    return buffer.toString();
  }

  /// Generate summary CSV with totals
  static String generateSummaryCSV({
    required List<Shift> shifts,
    required DateTime startDate,
    required DateTime endDate,
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
    buffer.write(generateShiftsCSV(shifts));

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
