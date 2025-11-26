class AuthService {
  // Plain text password storage - no encryption
  static String storePassword(String password) {
    return password; // Store as plain text
  }

  static bool verifyPassword(String password, String storedPassword) {
    return password == storedPassword; // Direct comparison
  }

  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  static String generateRandomPassword() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'PS${random % 10000}';
  }
}
