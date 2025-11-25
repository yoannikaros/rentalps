import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/console_with_type.dart';
import '../providers/rental_provider.dart';
import '../services/bluetooth_printer_service.dart';

class StartSessionDialog extends StatefulWidget {
  final ConsoleWithType console;

  const StartSessionDialog({
    super.key,
    required this.console,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog>
    with TickerProviderStateMixin {
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();
  int _selectedDuration = 60; // Default 1 hour
  bool _isLoading = false;
  bool _sessionStarted = false; // Tambahkan state untuk tracking session
  bool _isPrinting = false; // State untuk tracking printing
  final BluetoothPrinterService _printerService = BluetoothPrinterService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<int> _quickDurations = [30, 60, 120, 180, 240]; // in minutes

  @override
  void initState() {
    super.initState();
    _durationController.text = _selectedDuration.toString();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _atasNamaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: screenHeight * 0.9, // Maksimal 90% dari tinggi layar
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan gradient (fixed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getConsoleTypeColor(widget.console.type),
                            _getConsoleTypeColor(widget.console.type).withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.all(16),
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withValues(alpha: 0.2),
                          //     shape: BoxShape.circle,
                          //   ),
                          //   child: Icon(
                          //     Icons.gamepad_rounded,
                          //     color: Colors.white,
                          //     size: 32,
                          //   ),
                          // ),
                          // const SizedBox(height: 12),
                        
                          Text(
                            'Mulai Sesi Baru',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.console.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Console Info Card
                            _buildInfoCard(theme, colorScheme),
                            
                            const SizedBox(height: 20),
                            
                            // Atas Nama Input
                            _buildAtasNamaField(theme, colorScheme),
                            
                            const SizedBox(height: 20),
                            
                            // Duration Selection
                            _buildDurationSection(theme, colorScheme),
                            
                            const SizedBox(height: 20),
                            
                            // Cost Summary
                            _buildCostSummary(theme, colorScheme),
                          ],
                        ),
                      ),
                    ),
                    
                    // Actions (fixed at bottom)
                    _buildActions(theme, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getConsoleTypeColor(widget.console.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: _getConsoleTypeColor(widget.console.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarif per Jam',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(widget.console.hourlyRate)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtasNamaField(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atas Nama',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _atasNamaController,
          decoration: InputDecoration(
            hintText: 'Kosongkan untuk "umum"',
            prefixIcon: Icon(
              Icons.person_rounded,
              color: colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Durasi',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Quick Duration Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickDurations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                label: Text(_formatDuration(duration)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDuration = duration;
                      _durationController.text = duration.toString();
                    });
                  }
                },
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Custom Duration Input
        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Durasi kustom (menit)',
            prefixIcon: Icon(
              Icons.timer_rounded,
              color: colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          onChanged: (value) {
            final duration = int.tryParse(value);
            if (duration != null && duration > 0) {
              setState(() {
                _selectedDuration = duration;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCostSummary(ThemeData theme, ColorScheme colorScheme) {
    final atasNama = _atasNamaController.text.isEmpty ? "umum" : _atasNamaController.text;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Biaya',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Atas Nama', atasNama, theme, colorScheme),
          _buildSummaryRow('Durasi', _formatDuration(_selectedDuration), theme, colorScheme),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total Biaya', 
            'Rp ${_formatCurrency(_calculateCost())}', 
            theme, 
            colorScheme,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, ColorScheme colorScheme, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isTotal ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Text(
                _sessionStarted ? 'Tutup' : 'Batal',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol Print hanya muncul setelah sesi berhasil dimulai
          if (_sessionStarted) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_isLoading || _isPrinting) ? null : _showPrinterOptions,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                ),
                icon: _isPrinting 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : Icon(Icons.bluetooth_rounded, size: 18, color: colorScheme.primary),
                label: Text(
                  _isPrinting ? 'Printing...' : 'Print',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Expanded(
            //   child: FilledButton.icon(
            //     onPressed: (_isLoading || _isPrinting) ? null : _printReceipt,
            //     style: FilledButton.styleFrom(
            //       backgroundColor: Colors.green,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     icon: const Icon(Icons.print_rounded, size: 18),
            //     label: const Text('Print Teks'),
            //   ),
            // ),
          
          ],
          // Tombol "Mulai Sesi" hanya muncul sebelum sesi dimulai
          if (!_sessionStarted) ...[
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isLoading ? null : _startSession,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 18),
                          const SizedBox(width: 4),
                          Text('Mulai Sesi'),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  double _calculateCost() {
    final durationHours = _selectedDuration / 60.0;
    return durationHours * widget.console.hourlyRate;
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getConsoleTypeColor(String type) {
    switch (type) {
      case 'PS2':
        return Colors.grey[700]!;
      case 'PS3':
        return Colors.black87;
      case 'PS4':
        return Colors.blue[700]!;
      case 'PS5':
        return Colors.indigo[700]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _startSession() async {
    if (_selectedDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Durasi harus lebih dari 0 menit'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<RentalProvider>()
          .startSession(widget.console.id!, _selectedDuration, customerName: _atasNamaController.text.trim().isEmpty ? null : _atasNamaController.text.trim());

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set _sessionStarted menjadi true jika sesi berhasil dimulai
          if (success) {
            _sessionStarted = true;
          }
        });

        // Jangan langsung tutup dialog jika sesi berhasil dimulai
        if (!success) {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success 
                    ? 'Sesi berhasil dimulai! Anda dapat mencetak bukti transaksi.' 
                    : 'Gagal memulai sesi. Konsol mungkin sedang digunakan.'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Terjadi kesalahan saat memulai sesi'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _showPrinterOptions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BluetoothPrinterBottomSheet(
        onDeviceSelected: (device) => _printViaBluetooth(device),
      ),
    );
  }

  Future<void> _printViaBluetooth(BluetoothInfo device) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Connect to printer
      final connected = await _printerService.connectToPrinter(device.macAddress);
      
      if (connected) {
        // Print receipt
        final printed = await _printerService.printReceipt(
          consoleType: widget.console.name,
          atasNama: _atasNamaController.text,
          duration: _formatDuration(_selectedDuration),
          cost: _formatCurrency(_calculateCost()),
          startTime: DateTime.now(),
        );

        if (printed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Struk berhasil dicetak via Bluetooth!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Gagal mencetak struk');
        }
      } else {
        throw Exception('Gagal terhubung ke printer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }
}

class _BluetoothPrinterBottomSheet extends StatefulWidget {
  final Function(BluetoothInfo) onDeviceSelected;

  const _BluetoothPrinterBottomSheet({
    required this.onDeviceSelected,
  });

  @override
  State<_BluetoothPrinterBottomSheet> createState() => _BluetoothPrinterBottomSheetState();
}

class _BluetoothPrinterBottomSheetState extends State<_BluetoothPrinterBottomSheet> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      // Request permissions
      final hasPermissions = await _printerService.requestBluetoothPermissions();
      if (!hasPermissions) {
        throw Exception('Izin Bluetooth diperlukan');
      }

      // Check if Bluetooth is available
      final isAvailable = await _printerService.isBluetoothAvailable();
      if (!isAvailable) {
        throw Exception('Bluetooth tidak aktif');
      }

      // Get paired devices
      final devices = await _printerService.getPairedDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.bluetooth_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Pilih Printer Bluetooth',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _scanDevices,
                  icon: _isScanning 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          
          // Content
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: _buildContent(theme, colorScheme),
            ),
          ),
          
          // Close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanDevices,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_isScanning) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari printer Bluetooth...'),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_disabled_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada perangkat Bluetooth yang dipasangkan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanDevices,
              child: const Text('Scan Ulang'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.print, color: Colors.blue),
            title: Text(device.name),
            subtitle: Text(device.macAddress),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pop(context);
              widget.onDeviceSelected(device);
            },
          ),
        );
      },
    );
  }
}