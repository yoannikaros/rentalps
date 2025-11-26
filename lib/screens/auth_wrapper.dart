import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'rental_dashboard.dart';
import 'admin_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.initialize();
      } catch (e) {
        debugPrint('Error initializing auth: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat...'),
                ],
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          if (authProvider.isAdmin) {
            return const AdminDashboard();
          } else {
            return const RentalDashboard();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}