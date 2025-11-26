import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/session.dart';

class PdfService {
  static Future<Uint8List> generateMonthlyReport({
    required List<Map<String, dynamic>> sessionDetails,
    required String monthName,
    required int year,
  }) async {
    final pdf = pw.Document();

    // Calculate totals - properly include extended time and costs
    double totalRevenue = 0;
    int totalSessions = sessionDetails.length;
    int totalDuration = 0;

    for (var sessionData in sessionDetails) {
      final session = sessionData['session'] as Session;

      // Include extended cost in total revenue
      final totalExtendedCost =
          sessionData['totalExtendedCost'] as double? ?? 0.0;
      totalRevenue += session.totalCost + totalExtendedCost;

      // Include extended time in total duration
      final actualMinutes =
          session.actualDurationMinutes ?? session.durationMinutes;
      final totalExtendedMinutes =
          sessionData['totalExtendedMinutes'] as int? ?? 0;
      totalDuration += actualMinutes + totalExtendedMinutes;
    }

    // Group sessions by console type
    Map<String, List<Map<String, dynamic>>> sessionsByConsole = {};
    for (var sessionData in sessionDetails) {
      final consoleType = sessionData['consoleTypeName'] as String;
      if (!sessionsByConsole.containsKey(consoleType)) {
        sessionsByConsole[consoleType] = [];
      }
      sessionsByConsole[consoleType]!.add(sessionData);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(monthName, year),
            pw.SizedBox(height: 20),

            // Summary Cards
            _buildSummarySection(totalRevenue, totalSessions, totalDuration),
            pw.SizedBox(height: 30),

            // Console Performance
            _buildConsolePerformance(sessionsByConsole),
            pw.SizedBox(height: 30),

            // Session Details Table
            _buildSessionTable(sessionDetails),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String monthName, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF667eea), PdfColor.fromInt(0xFF764ba2)],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LAPORAN BULANAN',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '$monthName $year',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 18),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PS RENTX PRO',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    double totalRevenue,
    int totalSessions,
    int totalDuration,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryCard(
            'Total Pendapatan',
            _formatCurrency(totalRevenue),
            PdfColor.fromInt(0xFF4CAF50),
          ),
        ),
        pw.SizedBox(width: 15),
        pw.Expanded(
          child: _buildSummaryCard(
            'Total Sesi',
            totalSessions.toString(),
            PdfColor.fromInt(0xFF2196F3),
          ),
        ),
        pw.SizedBox(width: 15),
        pw.Expanded(
          child: _buildSummaryCard(
            'Total Durasi',
            _formatDuration(totalDuration),
            PdfColor.fromInt(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildConsolePerformance(
    Map<String, List<Map<String, dynamic>>> sessionsByConsole,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Performa per Konsol',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Tipe Konsol', isHeader: true),
                _buildTableCell('Jumlah Sesi', isHeader: true),
                _buildTableCell('Total Durasi', isHeader: true),
                _buildTableCell('Total Pendapatan', isHeader: true),
              ],
            ),
            // Data rows
            ...sessionsByConsole.entries.map((entry) {
              final consoleType = entry.key;
              final sessions = entry.value;
              final sessionCount = sessions.length;

              // Calculate total duration including extended time
              final totalDuration = sessions.fold<int>(0, (sum, sessionData) {
                final session = sessionData['session'] as Session;
                final actualMinutes =
                    session.actualDurationMinutes ?? session.durationMinutes;
                final totalExtendedMinutes =
                    sessionData['totalExtendedMinutes'] as int? ?? 0;
                return sum + actualMinutes + totalExtendedMinutes;
              });

              // Calculate total revenue including extended costs
              final totalRevenue = sessions.fold<double>(0, (sum, sessionData) {
                final session = sessionData['session'] as Session;
                final totalExtendedCost =
                    sessionData['totalExtendedCost'] as double? ?? 0.0;
                return sum + session.totalCost + totalExtendedCost;
              });

              return pw.TableRow(
                children: [
                  _buildTableCell(consoleType),
                  _buildTableCell(sessionCount.toString()),
                  _buildTableCell(_formatDuration(totalDuration)),
                  _buildTableCell(_formatCurrency(totalRevenue)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSessionTable(
    List<Map<String, dynamic>> sessionDetails,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detail Sesi',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Tanggal & Waktu', isHeader: true),
                _buildTableCell('Konsol', isHeader: true),
                _buildTableCell('Durasi', isHeader: true),
                _buildTableCell('Extend', isHeader: true),
                _buildTableCell('Biaya', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...sessionDetails.map((sessionData) {
              final session = sessionData['session'] as Session;
              final consoleType = sessionData['consoleTypeName'] as String;
              final extensionCount = sessionData['extensionCount'] as int? ?? 0;
              final totalExtendedMinutes =
                  sessionData['totalExtendedMinutes'] as int? ?? 0;
              final totalExtendedCost =
                  sessionData['totalExtendedCost'] as double? ?? 0.0;

              // Use actual duration which includes extended time
              final actualMinutes =
                  session.actualDurationMinutes ?? session.durationMinutes;

              // Format extension info
              String extensionInfo =
                  extensionCount > 0
                      ? '${extensionCount}x (${_formatDuration(totalExtendedMinutes)})'
                      : '-';

              return pw.TableRow(
                children: [
                  _buildTableCell(_formatDateTime(session.startTime)),
                  _buildTableCell(consoleType),
                  _buildTableCell(_formatDuration(actualMinutes)),
                  _buildTableCell(extensionInfo),
                  _buildTableCell(
                    _formatCurrency(session.totalCost + totalExtendedCost),
                  ),
                  _buildTableCell(session.isActive ? 'Aktif' : 'Selesai'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
      ),
    );
  }

  static String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static Future<String> savePdfToFile(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  static Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
      rethrow;
    }
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      // Save to temporary directory first
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }
}
