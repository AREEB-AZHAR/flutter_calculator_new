/// Model representing a saved account profile on this device.
class SavedAccountInfo {
  final String username;
  final String? email;
  final String displayName;
  final String? photoPath;
  final int primaryColor;
  final bool isBiometricEnabled;
  final bool isGoogleAccount;
  final String? createdAt;

  const SavedAccountInfo({
    required this.username,
    this.email,
    required this.displayName,
    this.photoPath,
    required this.primaryColor,
    required this.isBiometricEnabled,
    required this.isGoogleAccount,
    this.createdAt,
  });
}
