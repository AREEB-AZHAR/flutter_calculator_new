class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasSpecialChar;
  final bool hasThreeDigits;
  final int digitCount;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasSpecialChar,
    required this.hasThreeDigits,
    required this.digitCount,
  });

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasSpecialChar &&
      hasThreeDigits;

  List<String> get missingRequirements {
    final List<String> missing = [];
    if (!hasMinLength) missing.add('At least 10 characters long');
    if (!hasUppercase) missing.add('At least 1 uppercase letter (A-Z)');
    if (!hasLowercase) missing.add('At least 1 lowercase letter (a-z)');
    if (!hasSpecialChar) missing.add('At least 1 special character (!@#\$%^&*...)');
    if (!hasThreeDigits) missing.add('At least 3 numbers (found $digitCount)');
    return missing;
  }
}

class PasswordValidator {
  static const int minLength = 10;
  static const int minDigits = 3;

  /// Validates a password against strong security standards:
  /// - At least 10 characters long
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 special character
  /// - At least 3 numbers
  static PasswordValidationResult validate(String password) {
    final hasMinLength = password.length >= minLength;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    // Non-alphanumeric or common symbols: !@#$%^&*()_+-=[]{}|;':",./<>?`~
    final hasSpecialChar = RegExp(r'[^a-zA-Z0-9\s]').hasMatch(password);
    
    final digits = RegExp(r'\d').allMatches(password);
    final digitCount = digits.length;
    final hasThreeDigits = digitCount >= minDigits;

    return PasswordValidationResult(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasSpecialChar: hasSpecialChar,
      hasThreeDigits: hasThreeDigits,
      digitCount: digitCount,
    );
  }

  /// Basic email format validator
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$');
    return emailRegex.hasMatch(trimmed);
  }
}
