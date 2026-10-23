import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_security_bootstrap.dart';
import 'database/app_database.dart';
import '../utils/password_validator.dart';

abstract interface class RecoveryBackend {
  Future<Map<String, dynamic>> begin(String email);
  Future<Map<String, dynamic>> verify(String challengeId, String code);
}

class FirebaseRecoveryBackend implements RecoveryBackend {
  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, String> data,
  ) async {
    await FirebaseSecurityBootstrap.initialize();
    final response = await FirebaseFunctions.instance
        .httpsCallable(name)
        .call(data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> begin(String email) =>
      _call('beginLocalPasswordRecovery', {'email': email});
  @override
  Future<Map<String, dynamic>> verify(String challengeId, String code) => _call(
    'verifyLocalPasswordRecovery',
    {'challengeId': challengeId, 'code': code},
  );
}

class PasswordRecoveryService {
  final RecoveryBackend backend;
  final AppDatabase database;
  String? _challenge;
  String? _email;
  String? _username;
  String? _originalHash;
  int _generation = 0;
  PasswordRecoveryService({RecoveryBackend? backend, AppDatabase? database})
    : backend = backend ?? FirebaseRecoveryBackend(),
      database = database ?? AppDatabase.instance;

  void cancel() {
    _generation++;
    _challenge = null;
  }

  Future<void> begin(String email) async {
    final generation = ++_generation;
    _challenge = null;
    final normalized = email.trim().toLowerCase();
    if (!PasswordValidator.isValidEmail(normalized)) {
      throw StateError('Enter a valid registered email.');
    }
    final local = await database.getUserByEmail(normalized);
    if (local == null ||
        (local['email'] as String?)?.toLowerCase() != normalized) {
      throw StateError(
        'No local vault is bound to that email on this device. Google accounts can still sign in with Google.',
      );
    }
    final response = await backend.begin(normalized);
    if (generation != _generation) {
      throw StateError('Recovery request canceled.');
    }
    final id = response['challengeId'];
    if (id is! String || !RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw StateError('Could not create a recovery challenge.');
    }
    _challenge = id;
    _email = normalized;
    _username = local['username'] as String;
    _originalHash = local['password_hash'] as String;
  }

  Future<void> complete(
    String code,
    String password,
    String confirmation,
  ) async {
    if (_challenge == null || _email == null || _username == null) {
      throw StateError('Request a new recovery code.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      throw StateError('Enter the six-digit email code.');
    }
    final validation = PasswordValidator.validate(password);
    if (!validation.isValid) {
      throw StateError(
        'Password requirements: ${validation.missingRequirements.join(', ')}',
      );
    }
    if (password != confirmation) throw StateError('Passwords do not match.');
    final generation = _generation;
    final challenge = _challenge!;
    final response = await backend.verify(challenge, code.trim());
    if (generation != _generation) {
      throw StateError('Recovery request canceled.');
    }
    if (response['verified'] != true ||
        response['challengeId'] != challenge ||
        response['email'] != _email) {
      throw StateError('The server could not verify this recovery request.');
    }
    _challenge =
        null; // Server codes are single use, including when a later disk write fails.
    final updated = await database.updateRecoveredPassword(
      username: _username!,
      email: _email!,
      expectedHash: _originalHash!,
      newPassword: password,
    );
    if (!updated) {
      throw StateError(
        'The local account changed. Request a new code before retrying.',
      );
    }
  }
}
