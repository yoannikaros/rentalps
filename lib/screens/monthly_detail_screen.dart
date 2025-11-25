import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../services/sqlite_service.dart';
import '../services/pdf_service.dart';
import '../models/session.dart';

class MonthlyDetailScreen extends StatefulWidget {
  final int year;
  final int month;
  final String monthName;

  const MonthlyDetailScreen({
    super.key,
    required this.year,
    required this.month,
    required this.monthName,
  });

  @override
  State<MonthlyDetailScreen> createState() => _MonthlyDetailScreenState();
}

class _MonthlyDetailScreenState extends State<MonthlyDetailScreen>
    with TickerProviderStateMixin {
  final SQLiteService _sqliteService = SQLiteService();
  List<Map<String, dynamic>> _sessionDetails = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadSessionDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allSessions = await _sqliteService.getMonthlyReportData();

      // Filter sessions for the selected month and year
      final filteredSessions =
          allSessions.where((sessionData) {
            final session = sessionData['session'] as Session;
            final startTime = session.startTime;
            return startTime.year == widget.year &&
                startTime.month == widget.month;
          }).toList();

      // Sort by start time (newest first)
      filteredSessions.sort((a, b) {
        final sessionA = a['session'] as Session;
        final sessionB = b['session'] as Session;
        return sessionB.startTime.compareTo(sessionA.startTime);
      });

      setState(() {
        _sessionDetails = filteredSessions;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading session details: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Normal SliverAppBar with solid color
          SliverAppBar(
            expandedHeight: 80, // Reduced height
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF5B5FDE), // Modern solid blue
            title: Text(
              'Detail ${widget.monthName} ${widget.year}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              // PDF Export Button
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _sessionDetails.isNotEmpty ? _exportToPdf : null,
                  tooltip: 'Export ke PDF',
                ),
              ),
              // Refresh Button
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () {
                    _animationController.reset();
                    _loadSessionDetails();
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 5,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF667eea),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Memuat detail sesi...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _sessionDetails.isEmpty
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 5,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.event_busy_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Tidak ada sesi di bulan ini',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada aktivitas rental pada ${widget.monthName} ${widget.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Summary Card
                            _buildSummaryCard(),
                            const SizedBox(height: 24),

                            // Session List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _sessionDetails.length,
                              itemBuilder: (context, index) {
                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 50),
                                  ),
                                  curve: Curves.easeOutBack,
                                  child: _buildSessionCard(
                                    _sessionDetails[index],
                                    index,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_sessionDetails.isEmpty) return const SizedBox.shrink();

    int totalSessions = _sessionDetails.length;
    double totalRevenue = _sessionDetails.fold(0, (sum, sessionData) {
      final session = sessionData['session'] as Session;
      // Include extended cost in total revenue
      final totalExtendedCost =
          sessionData['totalExtendedCost'] as double? ?? 0.0;
      return sum + session.totalCost + totalExtendedCost;
    });
    double totalHours = _sessionDetails.fold(0, (sum, sessionData) {
      final session = sessionData['session'] as Session;
      // Include extended time in total hours
      final actualMinutes =
          session.actualDurationMinutes ?? session.durationMinutes;
      final totalExtendedMinutes =
          sessionData['totalExtendedMinutes'] as int? ?? 0;
      final totalMinutes = actualMinutes + totalExtendedMinutes;
      return sum + (totalMinutes / 60.0);
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50), // Solid green color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan ${widget.monthName} ${widget.year}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Sesi',
                  totalSessions.toString(),
                  Icons.play_circle_outline,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Jam',
                  '${totalHours.toStringAsFixed(1)}h',
                  Icons.access_time_outlined,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Pendapatan',
                  _formatCurrency(totalRevenue),
                  Icons.trending_up_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> sessionData, int index) {
    final session = sessionData['session'] as Session;
    final consoleName = sessionData['consoleName'] as String;
    final consoleTypeName = sessionData['consoleTypeName'] as String;
    final colorCode = sessionData['colorCode'] as String;

    // Get extension data from sessionData
    final extensionCount = sessionData['extensionCount'] as int? ?? 0;
    final totalExtendedMinutes =
        sessionData['totalExtendedMinutes'] as int? ?? 0;
    final totalExtendedCost =
        sessionData['totalExtendedCost'] as double? ?? 0.0;

    // Use the total duration (including extensions) for display
    final actualMinutes =
        session.actualDurationMinutes ?? session.durationMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with console info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(colorCode.replaceFirst('#', '0xFF')),
                ).withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(
                    color: Color(
                      int.parse(colorCode.replaceFirst('#', '0xFF')),
                    ),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(colorCode.replaceFirst('#', '0xFF')),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.gamepad_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consoleName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          consoleTypeName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatCurrency(session.totalCost),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Session details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer name if available
                  if (session.customerName != null &&
                      session.customerName!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Atas Nama: ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              session.customerName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Mulai',
                          _formatDateTime(session.startTime),
                          Icons.play_arrow_outlined,
                          const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          'Selesai',
                          session.endTime != null
                              ? _formatDateTime(session.endTime!)
                              : 'Belum selesai',
                          Icons.stop_outlined,
                          const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Durasi',
                          _formatDuration(actualMinutes),
                          Icons.timer_outlined,
                          const Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          'Tanggal',
                          DateFormat('dd MMM yyyy').format(session.startTime),
                          Icons.calendar_today_outlined,
                          const Color(0xFF607D8B),
                        ),
                      ),
                    ],
                  ),

                  // Show extension information if there are extensions
                  if (extensionCount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.extension_outlined,
                                color: const Color(0xFFFF9800),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Informasi Extension',
                                style: TextStyle(
                                  color: const Color(0xFFFF9800),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Durasi Asli: ${_formatDuration(session.originalDurationMinutes)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Tambahan: ${_formatDuration(totalExtendedMinutes)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Jumlah Extend: ${extensionCount}x',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Biaya Asli: ${_formatCurrency(session.originalCost)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Tambahan: ${_formatCurrency(totalExtendedCost)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Total: ${_formatCurrency(session.totalCost)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    if (_sessionDetails.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Membuat PDF...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
      );

      // Generate PDF
      final pdfBytes = await PdfService.generateMonthlyReport(
        sessionDetails: _sessionDetails,
        monthName: widget.monthName,
        year: widget.year,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show options dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Export PDF'),
                content: const Text('Pilih aksi untuk file PDF:'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _savePdf(pdfBytes);
                    },
                    child: const Text('Simpan'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sharePdf(pdfBytes);
                    },
                    child: const Text('Bagikan'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _printPdf(pdfBytes);
                    },
                    child: const Text('Print'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _savePdf(Uint8List pdfBytes) async {
    try {
      final fileName = 'Laporan_${widget.monthName}_${widget.year}.pdf';
      final filePath = await PdfService.savePdfToFile(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF disimpan: $filePath'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan PDF: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(Uint8List pdfBytes) async {
    try {
      final fileName = 'Laporan_${widget.monthName}_${widget.year}.pdf';
      await PdfService.sharePdf(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membagikan PDF: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _printPdf(Uint8List pdfBytes) async {
    try {
      await PdfService.printPdf(pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mencetak PDF: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
