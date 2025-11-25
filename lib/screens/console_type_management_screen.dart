import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/console_type.dart';
import '../services/sqlite_service.dart';

class ConsoleTypeManagementScreen extends StatefulWidget {
  const ConsoleTypeManagementScreen({super.key});

  @override
  State<ConsoleTypeManagementScreen> createState() =>
      _ConsoleTypeManagementScreenState();
}

class _ConsoleTypeManagementScreenState
    extends State<ConsoleTypeManagementScreen> {
  final SQLiteService _sqliteService = SQLiteService();
  List<ConsoleType> _consoleTypes = [];
  bool _isLoading = true;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadConsoleTypes();
  }

  Future<void> _loadConsoleTypes() async {
    setState(() => _isLoading = true);
    try {
      final consoleTypes = await _sqliteService.getAllConsoleTypes();
      setState(() {
        _consoleTypes = consoleTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading console types: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditDialog({ConsoleType? consoleType}) async {
    final nameController = TextEditingController(text: consoleType?.name ?? '');
    final rateController = TextEditingController(
      text: consoleType?.hourlyRate.toString() ?? '',
    );
    Color selectedColor = consoleType?.color ?? _availableColors.first;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    consoleType == null
                        ? 'Tambah Tipe Konsol'
                        : 'Edit Tipe Konsol',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Tipe (contoh: PS5)',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: rateController,
                          decoration: const InputDecoration(
                            labelText: 'Tarif per Jam (Rp)',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pilih Warna:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _availableColors.map((color) {
                                final isSelected =
                                    color.toARGB32() ==
                                    selectedColor.toARGB32();
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() => selectedColor = color);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.black
                                                : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty ||
                            rateController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon lengkapi semua field'),
                            ),
                          );
                          return;
                        }

                        final rate = double.tryParse(
                          rateController.text.trim(),
                        );
                        if (rate == null || rate <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tarif harus berupa angka positif'),
                            ),
                          );
                          return;
                        }

                        try {
                          final colorCode =
                              '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

                          if (consoleType == null) {
                            // Add new console type
                            final newConsoleType = ConsoleType(
                              name: nameController.text.trim().toUpperCase(),
                              hourlyRate: rate,
                              colorCode: colorCode,
                              createdAt: DateTime.now(),
                            );
                            await _sqliteService.insertConsoleType(
                              newConsoleType,
                            );
                          } else {
                            // Update existing console type
                            final updatedConsoleType = consoleType.copyWith(
                              name: nameController.text.trim().toUpperCase(),
                              hourlyRate: rate,
                              colorCode: colorCode,
                            );
                            await _sqliteService.updateConsoleType(
                              updatedConsoleType,
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(consoleType == null ? 'Tambah' : 'Update'),
                    ),
                  ],
                ),
          ),
    );

    if (result == true) {
      _loadConsoleTypes();
    }
  }

  Future<void> _deleteConsoleType(ConsoleType consoleType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Tipe Konsol'),
            content: Text(
              'Apakah Anda yakin ingin menghapus tipe "${consoleType.name}"?\n\nPerhatian: Tipe konsol yang masih digunakan oleh konsol tidak dapat dihapus.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _sqliteService.deleteConsoleType(consoleType.id!);
        _loadConsoleTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tipe konsol berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildConsoleTypeCard(ConsoleType consoleType, int index) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Console Type Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: consoleType.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: consoleType.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  consoleType.name.substring(0, 2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Console Type Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consoleType.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    consoleType.formattedRate,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
                    onPressed:
                        () => _showAddEditDialog(consoleType: consoleType),
                    tooltip: 'Edit',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.red.shade600,
                    ),
                    onPressed: () => _deleteConsoleType(consoleType),
                    tooltip: 'Hapus',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Manajemen Tipe Konsol',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF5B5FDE),
                              ),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Memuat data tipe konsol...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _consoleTypes.isEmpty
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
                                Icons.category_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Belum ada tipe konsol',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan tipe konsol pertama Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ...List.generate(
                            _consoleTypes.length,
                            (index) => _buildConsoleTypeCard(
                              _consoleTypes[index],
                              index,
                            ),
                          ),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5B5FDE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B5FDE).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tambah Tipe',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
