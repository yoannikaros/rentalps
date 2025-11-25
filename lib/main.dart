import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/rental_provider.dart';
import 'screens/rental_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request Bluetooth permissions at app startup
  await _requestBluetoothPermissions();

  runApp(const MyApp());
}

Future<void> _requestBluetoothPermissions() async {
  try {
    // Request multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
    
    // Log permission status for debugging
    statuses.forEach((permission, status) {
      debugPrint('Permission ${permission.toString()}: ${status.toString()}');
    });
    
    // Check if critical permissions are granted
    bool bluetoothConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    bool locationGranted = statuses[Permission.location]?.isGranted ?? 
                          statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    
    if (!bluetoothConnectGranted || !locationGranted) {
      debugPrint('Warning: Some Bluetooth permissions were not granted');
      debugPrint('Bluetooth Connect: $bluetoothConnectGranted');
      debugPrint('Location: $locationGranted');
    } else {
      debugPrint('All Bluetooth permissions granted successfully');
    }
  } catch (e) {
    debugPrint('Error requesting Bluetooth permissions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RentalProvider(),
      child: MaterialApp(
        title: 'RentalPS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const RentalDashboard(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}