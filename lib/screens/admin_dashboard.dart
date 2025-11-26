import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/rental_provider.dart';
import '../models/session.dart';
import 'console_management_screen.dart';
import 'console_type_management_screen.dart';
import 'monthly_report_screen.dart';
import 'user_management_screen.dart';
import 'rental_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                if (authProvider.currentUser != null)
                  Text(
                    authProvider.currentUser!.fullName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.indigo[700],
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context, authProvider);
                  } else if (value == 'rental_mode') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RentalDashboard(),
                      ),
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'rental_mode',
                        child: Row(
                          children: [
                            Icon(Icons.videogame_asset),
                            SizedBox(width: 8),
                            Text('Mode Rental'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[700]!, Colors.indigo[50]!],
          ),
        ),
        child: Consumer2<AuthProvider, RentalProvider>(
          builder: (context, authProvider, rentalProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Section
                  _buildWelcomeCard(context, authProvider),
                  const SizedBox(height: 20),

                  // Quick Stats
                  _buildQuickStats(rentalProvider),
                  const SizedBox(height: 20),

                  // Admin Features Grid
                  _buildAdminFeaturesGrid(context),
                  const SizedBox(height: 20),

                  // Recent Activity
                  _buildRecentActivitySection(rentalProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.indigo[100],
            child: Icon(
              Icons.admin_panel_settings,
              size: 30,
              color: Colors.indigo[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (authProvider.currentUser != null) ...[
                  Text(
                    authProvider.currentUser!.fullName,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  Text(
                    authProvider.currentUser!.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(RentalProvider rentalProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Konsol',
            '${rentalProvider.consoles.length}',
            Icons.gamepad,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Sesi Aktif',
            '${rentalProvider.activeSessions.length}',
            Icons.play_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Tipe',
            '4',
            Icons.category,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeaturesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fitur Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid: 3 columns for wide screens, 2 for medium, 1 for narrow
            int crossAxisCount;
            double childAspectRatio;

            if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.2;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
              childAspectRatio = 1.4;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 2.5;
            }

            double crossAxisSpacing = 16;
            double mainAxisSpacing = 16;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: [
                _buildFeatureCard(
                  context,
                  'Manajemen Konsol',
                  'Tambah, edit, dan hapus konsol',
                  Icons.gamepad,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsoleManagementScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Tipe Konsol',
                  'Kelola tipe dan harga konsol',
                  Icons.category,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsoleTypeManagementScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Laporan Bulanan',
                  'Lihat laporan pendapatan',
                  Icons.bar_chart,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyReportScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Manajemen User',
                  'Kelola admin dan karyawan',
                  Icons.people,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(RentalProvider rentalProvider) {
    // Combine active sessions and recent completed sessions
    final List<Widget> activityItems = [];

    // Add active sessions
    for (var session in rentalProvider.activeSessions) {
      final console =
          rentalProvider.consoles
              .where((c) => c.id == session.consoleId)
              .firstOrNull;
      activityItems.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.green[100],
            child: Icon(
              Icons.play_arrow,
              color: Colors.green[700],
            ),
          ),
          title: Text(console?.name ?? 'Unknown Console'),
          subtitle: Text(
            'Customer: ${session.customerName ?? "Guest"}\n'
            'Durasi: ${session.durationMinutes} menit',
          ),
          trailing: Text(
            'Rp ${session.totalCost.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Add recent completed sessions
    for (var sessionData in rentalProvider.recentCompletedSessions) {
      final session = Session.fromMap(sessionData);
      final consoleName = sessionData['console_name'] ?? 'Unknown Console';

      activityItems.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.grey[100],
            child: Icon(
              Icons.check_circle,
              color: Colors.grey[700],
            ),
          ),
          title: Text(consoleName),
          subtitle: Text(
            'Customer: ${session.customerName ?? "Guest"}\n'
            'Durasi: ${session.durationMinutes} menit',
          ),
          trailing: Text(
            'Rp ${session.totalCost.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Terkini',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              activityItems.isEmpty
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Belum ada aktivitas rental'),
                    ),
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activityItems.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) => activityItems[index],
                  ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apakah Anda yakin ingin keluar?'),
                const SizedBox(height: 16),
                if (authProvider.currentUser != null) ...[
                  Text(
                    'User: ${authProvider.currentUser!.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Role: ${authProvider.currentUser!.role.displayName}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed:
                        authProvider.isLoading
                            ? null
                            : () async {
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const RentalDashboard(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        authProvider.isLoading
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Logout'),
                  );
                },
              ),
            ],
          ),
    );
  }
}
