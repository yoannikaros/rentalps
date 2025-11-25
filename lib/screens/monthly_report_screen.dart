import 'package:flutter/material.dart';
import '../services/sqlite_service.dart';
import '../models/session.dart';
import 'monthly_detail_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final SQLiteService _sqliteService = SQLiteService();
  List<MonthlyReportData> _monthlyReports = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cache for performance optimization
  static List<MonthlyReportData>? _cachedReports;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced animation duration
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut, // Faster curve
      ),
    );
    _loadMonthlyReports();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyReports() async {
    // Check cache first
    if (_cachedReports != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
      setState(() {
        _monthlyReports = _cachedReports!;
        _isLoading = false;
      });
      _animationController.forward();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _getMonthlyReports();

      // Update cache
      _cachedReports = reports;
      _lastCacheTime = DateTime.now();

      if (mounted) {
        setState(() {
          _monthlyReports = reports;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
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

  // Force refresh (clear cache)
  Future<void> _forceRefresh() async {
    _cachedReports = null;
    _lastCacheTime = null;
    _animationController.reset();
    await _loadMonthlyReports();
  }

  Future<List<MonthlyReportData>> _getMonthlyReports() async {
    // Get all completed sessions (not active) with console and console type data
    final sessions = await _sqliteService.getMonthlyReportData();

    // Group sessions by month and year
    Map<String, MonthlyReportData> monthlyData = {};

    for (var sessionData in sessions) {
      final session = sessionData['session'] as Session;
      // final consoleName = sessionData['consoleName'] as String;
      final consoleTypeName = sessionData['consoleTypeName'] as String;
      // final hourlyRate = sessionData['hourlyRate'] as double;
      final colorCode = sessionData['colorCode'] as String;

      // Get extension data
      final totalExtendedMinutes =
          sessionData['totalExtendedMinutes'] as int? ?? 0;
      final totalExtendedCost =
          sessionData['totalExtendedCost'] as double? ?? 0.0;
      final extensionCount = sessionData['extensionCount'] as int? ?? 0;

      final startTime = session.startTime;
      final monthKey =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = MonthlyReportData(
          year: startTime.year,
          month: startTime.month,
          totalHours: 0,
          totalRevenue: 0,
          sessionCount: 0,
          totalExtensions: 0,
          consoleTypeBreakdown: {},
        );
      }

      final data = monthlyData[monthKey]!;
      // Calculate total duration including extensions
      final actualMinutes =
          session.actualDurationMinutes ?? session.durationMinutes;
      final totalMinutes = actualMinutes + totalExtendedMinutes;
      final hours = totalMinutes / 60.0;

      // Calculate total revenue including extensions
      final totalRevenue = session.totalCost + totalExtendedCost;

      data.totalHours += hours;
      data.totalRevenue += totalRevenue;
      data.sessionCount += 1;
      data.totalExtensions += extensionCount;

      // Console type breakdown
      if (!data.consoleTypeBreakdown.containsKey(consoleTypeName)) {
        data.consoleTypeBreakdown[consoleTypeName] = ConsoleTypeData(
          name: consoleTypeName,
          hours: 0,
          revenue: 0,
          sessionCount: 0,
          colorCode: colorCode,
        );
      }

      data.consoleTypeBreakdown[consoleTypeName]!.hours += hours;
      data.consoleTypeBreakdown[consoleTypeName]!.revenue += totalRevenue;
      data.consoleTypeBreakdown[consoleTypeName]!.sessionCount += 1;
    }

    return monthlyData.values.toList()..sort(
      (a, b) => DateTime(b.year, b.month).compareTo(DateTime(a.year, a.month)),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
            title: const Text(
              'Laporan Bulanan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _forceRefresh,
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
                              'Memuat laporan...',
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
                    : _monthlyReports.isEmpty
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
                                Icons.analytics_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Belum ada data laporan',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mulai sesi rental untuk melihat laporan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
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
                            // Summary Stats
                            if (_monthlyReports.isNotEmpty) ...[
                              _buildOverallSummary(),
                              const SizedBox(height: 24),
                            ],

                            // Monthly Reports
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _monthlyReports.length,
                              itemBuilder: (context, index) {
                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 100),
                                  ),
                                  curve: Curves.easeOutBack,
                                  child: _buildMonthlyReportCard(
                                    _monthlyReports[index],
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

  Widget _buildOverallSummary() {
    if (_monthlyReports.isEmpty) return const SizedBox.shrink();

    double totalHours = _monthlyReports.fold(
      0,
      (sum, report) => sum + report.totalHours,
    );
    double totalRevenue = _monthlyReports.fold(
      0,
      (sum, report) => sum + report.totalRevenue,
    );
    int totalSessions = _monthlyReports.fold(
      0,
      (sum, report) => sum + report.sessionCount,
    );
    int totalExtensions = _monthlyReports.fold(
      0,
      (sum, report) => sum + report.totalExtensions,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF5B5FDE), // Modern solid blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B5FDE).withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Keseluruhan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Total Sesi',
                  value: totalSessions.toString(),
                  icon: Icons.play_circle_outline,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  title: 'Total Jam',
                  value: '${totalHours.toStringAsFixed(1)}h',
                  icon: Icons.access_time_outlined,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  title: 'Total Pendapatan',
                  value: 'Rp ${(totalRevenue / 1000).toStringAsFixed(0)}K',
                  icon: Icons.trending_up_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Total Extension',
                  value: totalExtensions.toString(),
                  icon: Icons.extension_outlined,
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space
              const Expanded(child: SizedBox()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportCard(MonthlyReportData report, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MonthlyDetailScreen(
                  year: report.year,
                  month: report.month,
                  monthName: _getMonthName(report.month),
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with solid color
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[500], // Solid blue color
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getMonthName(report.month)} ${report.year}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report.sessionCount} sesi rental',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernSummaryCard(
                            'Total Jam',
                            '${report.totalHours.toStringAsFixed(1)} jam',
                            Icons.access_time_rounded,
                            const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernSummaryCard(
                            'Pendapatan',
                            'Rp ${(report.totalRevenue / 1000).toStringAsFixed(0)}K',
                            Icons.attach_money_rounded,
                            const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Console Type Breakdown
                    if (report.consoleTypeBreakdown.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.gamepad_outlined,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Breakdown per Tipe Konsol',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...report.consoleTypeBreakdown.values.map(
                        (consoleData) =>
                            _buildModernConsoleTypeRow(consoleData),
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

  Widget _buildModernSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernConsoleTypeRow(ConsoleTypeData consoleData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(
                int.parse(consoleData.colorCode.replaceFirst('#', '0xFF')),
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Color(
                    int.parse(consoleData.colorCode.replaceFirst('#', '0xFF')),
                  ).withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consoleData.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${consoleData.sessionCount} sesi',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${consoleData.hours.toStringAsFixed(1)} jam',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Rp ${(consoleData.revenue / 1000).toStringAsFixed(0)}K',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Optimized summary item widget with const constructor
class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class MonthlyReportData {
  final int year;
  final int month;
  double totalHours;
  double totalRevenue;
  int sessionCount;
  int totalExtensions;
  Map<String, ConsoleTypeData> consoleTypeBreakdown;

  MonthlyReportData({
    required this.year,
    required this.month,
    required this.totalHours,
    required this.totalRevenue,
    required this.sessionCount,
    required this.totalExtensions,
    required this.consoleTypeBreakdown,
  });
}

class ConsoleTypeData {
  final String name;
  double hours;
  double revenue;
  int sessionCount;
  final String colorCode;

  ConsoleTypeData({
    required this.name,
    required this.hours,
    required this.revenue,
    required this.sessionCount,
    required this.colorCode,
  });
}
