import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role.isAdmin ?? false;
  bool get isEmployee => _currentUser?.role.isEmployee ?? false;

  // Initialize auth state by checking if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final user = await DatabaseHelper().getUserById(userId);
        if (user != null) {
          _currentUser = user;
        } else {
          // User not found in database, clear stored credentials
          await prefs.remove('user_id');
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper().authenticateAndGetUser(
        username,
        password,
      );

      if (user != null) {
        _currentUser = user;

        // Save user ID to shared preferences for auto-login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id!);

        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Username/email atau password salah';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Register method
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (username.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          fullName.isEmpty) {
        _errorMessage = 'Semua field harus diisi';
        notifyListeners();
        return false;
      }

      if (password != confirmPassword) {
        _errorMessage = 'Password tidak cocok';
        notifyListeners();
        return false;
      }

      if (!AuthService.isPasswordStrong(password)) {
        _errorMessage =
            'Password minimal 8 karakter, mengandung huruf besar, kecil, dan angka';
        notifyListeners();
        return false;
      }

      // Check if username or email already exists
      final dbHelper = DatabaseHelper();
      final usernameExists = await dbHelper.isUsernameExists(username);
      final emailExists = await dbHelper.isEmailExists(email);

      if (usernameExists) {
        _errorMessage = 'Username sudah digunakan';
        notifyListeners();
        return false;
      }

      if (emailExists) {
        _errorMessage = 'Email sudah digunakan';
        notifyListeners();
        return false;
      }

      // Create new user
      final plainPassword = AuthService.storePassword(password);
      final newUser = User(
        username: username,
        email: email,
        passwordHash: plainPassword,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );

      await dbHelper.insertUser(newUser);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');

      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal logout: ${e.toString()}';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String fullName,
    required String email,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (fullName.isEmpty || email.isEmpty) {
        _errorMessage = 'Semua field harus diisi';
        notifyListeners();
        return false;
      }

      // Check if email is being changed and if new email already exists
      if (email != _currentUser!.email) {
        final emailExists = await DatabaseHelper().isEmailExists(email);
        if (emailExists) {
          _errorMessage = 'Email sudah digunakan';
          notifyListeners();
          return false;
        }
      }

      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
      );

      await DatabaseHelper().updateUser(updatedUser);
      _currentUser = updatedUser;

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        _errorMessage = 'Semua field harus diisi';
        notifyListeners();
        return false;
      }

      if (newPassword != confirmPassword) {
        _errorMessage = 'Password baru tidak cocok';
        notifyListeners();
        return false;
      }

      if (!AuthService.isPasswordStrong(newPassword)) {
        _errorMessage =
            'Password minimal 8 karakter, mengandung huruf besar, kecil, dan angka';
        notifyListeners();
        return false;
      }

      // Verify current password
      if (!AuthService.verifyPassword(
        currentPassword,
        _currentUser!.passwordHash,
      )) {
        _errorMessage = 'Password saat ini salah';
        notifyListeners();
        return false;
      }

      // Update password
      final plainPassword = AuthService.storePassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: plainPassword);

      await DatabaseHelper().updateUser(updatedUser);
      _currentUser = updatedUser;

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah password: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh user data from database
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = await DatabaseHelper().getUserById(_currentUser!.id!);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
      } else {
        // User not found, logout
        await logout();
      }
    } catch (e) {
      _errorMessage = 'Gagal memperbarui data pengguna: ${e.toString()}';
      notifyListeners();
    }
  }
}
