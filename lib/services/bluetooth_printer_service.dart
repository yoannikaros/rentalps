import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';

class BluetoothInfo {
  final String name;
  final String macAddress;

  BluetoothInfo({required this.name, required this.macAddress});
}

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  // Request Bluetooth permissions
  Future<bool> requestBluetoothPermissions() async {
    try {
      final bluetoothPermission = await Permission.bluetoothConnect.request();
      final locationPermission = await Permission.location.request();
      
      return bluetoothPermission.isGranted && locationPermission.isGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('Error checking Bluetooth availability: $e');
      return false;
    }
  }

  // Get paired Bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices.map((device) => BluetoothInfo(
        name: device.name,
        macAddress: device.macAdress,
      )).toList();
    } catch (e) {
      debugPrint('Error getting paired devices: $e');
      return [];
    }
  }

  // Connect to a Bluetooth printer
  Future<bool> connectToPrinter(String macAddress) async {
    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      return false;
    }
  }

  // Disconnect from printer
  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      debugPrint('Error disconnecting: $e');
      return false;
    }
  }

  // Check connection status
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      debugPrint('Error checking connection status: $e');
      return false;
    }
  }

  // Print receipt with detailed information
  Future<bool> printReceipt({
    required String consoleType,
    required String atasNama,
    required String duration,
    required String cost,
    required DateTime startTime,
  }) async {
    try {
      final isConnected = await this.isConnected();
      if (!isConnected) {
        return false;
      }

      // Generate receipt using esc_pos_utils_plus
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text('GIDDEN GAME',
          styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Struk Pembayaran',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      // Receipt details
      bytes += generator.text('Console: $consoleType');
      bytes += generator.text('Atas Nama: $atasNama');
      bytes += generator.text('Durasi: $duration');
      bytes += generator.text('Biaya: $cost');
      bytes += generator.text('Waktu Mulai: ${_formatDateTime(startTime)}');
      bytes += generator.hr();

      // Footer
      bytes += generator.text('Terima kasih!',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Selamat bermain!',
          styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.feed(3);
      bytes += generator.cut();

      // Send to printer
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  // Print test page
  Future<bool> printTest() async {
    try {
      final isConnected = await this.isConnected();
      if (!isConnected) {
        return false;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text('TEST PRINT',
          styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2));
      bytes += generator.text('Printer berhasil terhubung!',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('Error printing test: $e');
      return false;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}