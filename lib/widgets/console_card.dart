import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/console_with_type.dart';
import '../providers/rental_provider.dart';

class ConsoleCard extends StatelessWidget {
  final ConsoleWithType console;
  final VoidCallback? onTap;

  const ConsoleCard({
    super.key,
    required this.console,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RentalProvider>(
      builder: (context, rentalProvider, child) {
        final status = rentalProvider.getConsoleStatus(console);
        final statusColor = rentalProvider.getConsoleStatusColor(console);
        final isActive = console.isActive;

        return GestureDetector(
          onTap: onTap,
          child: Container(
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
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced from 16 to 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Console Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                    decoration: BoxDecoration(
                      color: _getConsoleTypeColor(console.type),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      console.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10, // Reduced from 12 to 10
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  
                  // Console Name
                  Flexible(
                    child: Text(
                      console.name,
                      style: const TextStyle(
                        fontSize: 14, // Reduced from 16 to 14
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  
                  // Hourly Rate
                  Text(
                    'Rp ${_formatCurrency(console.hourlyRate)}/jam',
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14 to 12
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Status Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6), // Reduced from 8 to 6
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(status, isActive),
                          color: statusColor,
                          size: 20, // Reduced from 24 to 20
                        ),
                        const SizedBox(height: 2), // Reduced from 4 to 2
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12, // Reduced from 14 to 12
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  IconData _getStatusIcon(String status, bool isActive) {
    if (status == 'READY') {
      return Icons.check_circle;
    } else if (status == 'Selesai') {
      return Icons.error;
    } else if (isActive) {
      return Icons.timer;
    } else {
      return Icons.play_circle;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}