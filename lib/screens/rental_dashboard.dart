import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';
import '../models/console_with_type.dart';
import '../widgets/console_card.dart';
import '../widgets/start_session_dialog.dart';
import '../services/bluetooth_printer_service.dart';
import 'console_management_screen.dart';
import 'console_type_management_screen.dart';
import 'monthly_report_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class RentalDashboard extends StatelessWidget {
  const RentalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RENTAL PS',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'console_management':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsoleManagementScreen(),
                    ),
                  );
                  break;
                case 'console_type_management':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsoleTypeManagementScreen(),
                    ),
                  );
                  break;
                case 'monthly_report':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyReportScreen(),
                    ),
                  );
                  break;
                case 'privacy_policy':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                  break;
                case 'terms_of_service':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'console_management',
                    child: Row(
                      children: [
                        Icon(Icons.gamepad),
                        SizedBox(width: 8),
                        Text('Kelola Konsol'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'console_type_management',
                    child: Row(
                      children: [
                        Icon(Icons.category),
                        SizedBox(width: 8),
                        Text('Kelola Tipe Konsol'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'monthly_report',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart),
                        SizedBox(width: 8),
                        Text('Laporan Bulanan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'privacy_policy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip),
                        SizedBox(width: 8),
                        Text('Privacy Policy'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'terms_of_service',
                    child: Row(
                      children: [
                        Icon(Icons.description),
                        SizedBox(width: 8),
                        Text('Terms of Service'),
                      ],
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<RentalProvider>().loadConsoles();
              context.read<RentalProvider>().loadActiveSessions();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
          ),
        ),
        child: Consumer<RentalProvider>(
          builder: (context, rentalProvider, child) {
            if (rentalProvider.consoles.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data konsol...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Info
                      Container(
                        padding: const EdgeInsets.all(
                          12,
                        ), // Reduced from 16 to 12
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Total Konsol',
                                '${rentalProvider.consoles.length}',
                                Icons.gamepad,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoCard(
                                'Sedang Aktif',
                                '${rentalProvider.activeSessions.length}',
                                Icons.play_circle,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoCard(
                                'Tersedia',
                                '${rentalProvider.consoles.length - rentalProvider.activeSessions.length}',
                                Icons.check_circle,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Console Grid Title
                      const Text(
                        'Daftar Konsol',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ]),
                  ),
                ),

                // Console Grid
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive grid
                    int crossAxisCount = 2;
                    if (constraints.crossAxisExtent > 600) {
                      crossAxisCount = 3;
                    }
                    if (constraints.crossAxisExtent > 900) {
                      crossAxisCount = 4;
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio:
                              0.75, // Increased from 0.85 to give more height
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final console = rentalProvider.consoles[index];
                          return ConsoleCard(
                            console: console,
                            onTap: () => _handleConsoleTap(context, console),
                          );
                        }, childCount: rentalProvider.consoles.length),
                      ),
                    );
                  },
                ),

                // Add bottom padding
                const SliverPadding(padding: EdgeInsets.only(bottom: 16.0)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28), // Reduced from 32 to 28
        const SizedBox(height: 6), // Reduced from 8 to 6
        Text(
          value,
          style: TextStyle(
            fontSize: 20, // Reduced from 24 to 20
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11, // Reduced from 12 to 11
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _handleConsoleTap(BuildContext context, ConsoleWithType console) {
    final rentalProvider = context.read<RentalProvider>();
    final activeSession = rentalProvider.getActiveSessionForConsole(
      console.id!,
    );

    if (activeSession == null) {
      // Start new session
      showDialog(
        context: context,
        builder: (context) => StartSessionDialog(console: console),
      );
    } else {
      // Show session options
      _showSessionOptions(context, console, activeSession);
    }
  }

  void _showSessionOptions(
    BuildContext context,
    ConsoleWithType console,
    session,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  console.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.print, color: Colors.green),
                  title: const Text('Print Bukti Transaksi'),
                  onTap: () {
                    Navigator.pop(context);
                    _printReceipt(context, console, session);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.blue),
                  title: const Text('Perpanjang Waktu'),
                  onTap: () {
                    Navigator.pop(context);
                    _showExtendDialog(context, session);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.stop_circle, color: Colors.red),
                  title: const Text('Akhiri Sesi'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmEndSession(context, session);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showExtendDialog(BuildContext context, session) {
    final durationController = TextEditingController();
    double additionalCost = 0.0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Perpanjang Waktu'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tambahan waktu (menit)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) async {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            final cost = await context
                                .read<RentalProvider>()
                                .calculateAdditionalCost(session.id!, minutes);
                            setState(() {
                              additionalCost = cost;
                            });
                          } else {
                            setState(() {
                              additionalCost = 0.0;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (additionalCost > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Biaya tambahan:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Rp ${additionalCost.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final minutes = int.tryParse(durationController.text);
                        if (minutes != null && minutes > 0) {
                          final success = await context
                              .read<RentalProvider>()
                              .extendSession(session.id!, minutes);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Waktu berhasil diperpanjang'
                                      : 'Gagal memperpanjang waktu',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Perpanjang'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _confirmEndSession(BuildContext context, session) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Akhiri Sesi'),
            content: const Text('Apakah Anda yakin ingin mengakhiri sesi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await context
                      .read<RentalProvider>()
                      .endSession(session.id!);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Sesi berhasil diakhiri'
                              : 'Gagal mengakhiri sesi',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Akhiri'),
              ),
            ],
          ),
    );
  }

  void _printReceipt(
    BuildContext context,
    ConsoleWithType console,
    session,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Mencetak bukti transaksi...'),
                ],
              ),
            ),
      );

      final bluetoothService = BluetoothPrinterService();

      // Check if Bluetooth is available
      final isBluetoothAvailable =
          await bluetoothService.isBluetoothAvailable();
      if (!isBluetoothAvailable) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog(
            context,
            'Bluetooth tidak tersedia atau tidak aktif',
          );
        }
        return;
      }

      // Check if printer is connected
      final isConnected = await bluetoothService.isConnected();
      if (!isConnected) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          _showPrinterSelectionDialog(context, console, session);
        }
        return;
      }

      // Print the receipt
      final success = await bluetoothService.printReceipt(
        consoleType: console.type,
        atasNama:
            'Customer', // You might want to add customer name to session model
        duration: '${session.durationMinutes} menit',
        cost: 'Rp ${session.totalCost.toStringAsFixed(0)}',
        startTime: session.startTime,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Bukti transaksi berhasil dicetak'
                  : 'Gagal mencetak bukti transaksi',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  void _showPrinterSelectionDialog(
    BuildContext context,
    ConsoleWithType console,
    session,
  ) async {
    final bluetoothService = BluetoothPrinterService();

    // Request permissions
    final hasPermissions = await bluetoothService.requestBluetoothPermissions();
    if (!hasPermissions) {
      if (context.mounted) {
        _showErrorDialog(context, 'Izin Bluetooth diperlukan untuk mencetak');
      }
      return;
    }

    // Get paired devices
    final devices = await bluetoothService.getPairedDevices();

    if (devices.isEmpty) {
      if (context.mounted) {
        _showErrorDialog(context, 'Tidak ada printer Bluetooth yang terpasang');
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Pilih Printer'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(device.name),
                      subtitle: Text(device.macAddress),
                      onTap: () async {
                        Navigator.pop(context);
                        await _connectAndPrint(
                          context,
                          console,
                          session,
                          device.macAddress,
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _connectAndPrint(
    BuildContext context,
    ConsoleWithType console,
    session,
    String macAddress,
  ) async {
    try {
      // Show connecting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Menghubungkan ke printer...'),
                ],
              ),
            ),
      );

      final bluetoothService = BluetoothPrinterService();

      // Connect to printer
      final connected = await bluetoothService.connectToPrinter(macAddress);

      if (!connected) {
        if (context.mounted) {
          Navigator.pop(context); // Close connecting dialog
          _showErrorDialog(context, 'Gagal terhubung ke printer');
        }
        return;
      }

      // Print the receipt
      final success = await bluetoothService.printReceipt(
        consoleType: console.type,
        atasNama: 'Customer',
        duration: '${session.durationMinutes} menit',
        cost: 'Rp ${session.totalCost.toStringAsFixed(0)}',
        startTime: session.startTime,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close connecting dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Bukti transaksi berhasil dicetak'
                  : 'Gagal mencetak bukti transaksi',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close connecting dialog
        _showErrorDialog(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
