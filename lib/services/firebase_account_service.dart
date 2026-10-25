import 'package:firebase_auth/firebase_auth.dart';
import '../utils/password_validator.dart';
import 'database/app_database.dart';
import 'firebase_security_bootstrap.dart';
import 'auth_session_barrier.dart';

String accountAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'operation-not-allowed' =>
        'Email/password sign-in must be enabled in Firebase Authentication.',
      'network-request-failed' =>
        'Connect to the internet to sign in or recover your Firebase account. Enrolled biometrics can still unlock saved local data.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'email-already-in-use' =>
        'This email already has a Firebase account. Sign in or reset its password.',
      'weak-password' =>
        'Firebase requires a stronger password. Your saved vault is unchanged.',
      'requires-recent-login' => 'Sign in again before changing your password.',
      _ =>
        'Unable to authenticate. Check your Firebase email and password, or use Continue with Google for a Google account.',
    };
  }
  return error.toString().replaceFirst('Bad state: ', '');
}

class FirebaseAccount {
  final String uid;
  final String email;
  final bool emailVerified;
  final Set<String> providers;
  const FirebaseAccount(
    this.uid,
    this.email,
    this.emailVerified,
    this.providers,
  );
}

abstract interface class AccountAuthBackend {
  FirebaseAccount? get current;
  Future<FirebaseAccount> signIn(String email, String password);
  Future<FirebaseAccount> create(String email, String password);
  Future<void> sendVerification();
  Future<void> sendReset(String email);
  Future<void> changePassword(
    String uid,
    String email,
    String oldPassword,
    String newPassword,
  );
  Future<void> signOut();
}

class FirebaseAccountBackend implements AccountAuthBackend {
  FirebaseAccount? _snapshot(User? user) => user?.email == null
      ? null
      : FirebaseAccount(
          user!.uid,
          user.email!.toLowerCase(),
          user.emailVerified,
          user.providerData.map((p) => p.providerId).toSet(),
        );
  @override
  FirebaseAccount? get current {
    try {
      return _snapshot(FirebaseAuth.instance.currentUser);
    } catch (_) {
      return null;
    }
  }

  Future<FirebaseAuth> _auth() async {
    await AuthSessionBarrier.pendingSignOut;
    await FirebaseSecurityBootstrap.initialize();
    return FirebaseAuth.instance;
  }

  @override
  Future<FirebaseAccount> signIn(String email, String password) async =>
      _snapshot(
        (await (await _auth()).signInWithEmailAndPassword(
          email: email,
          password: password,
        )).user,
      )!;
  @override
  Future<FirebaseAccount> create(String email, String password) async =>
      _snapshot(
        (await (await _auth()).createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).user,
      )!;
  @override
  Future<void> sendVerification() async =>
      (await _auth()).currentUser!.sendEmailVerification();
  @override
  Future<void> sendReset(String email) async =>
      (await _auth()).sendPasswordResetEmail(email: email);
  @override
  Future<void> changePassword(
    String uid,
    String email,
    String oldPassword,
    String newPassword,
  ) async {
    final auth = await _auth();
    final user = auth.currentUser;
    if (user == null ||
        user.uid != uid ||
        user.email?.toLowerCase() != email.toLowerCase()) {
      throw StateError('Sign in to this Firebase account again.');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: oldPassword),
    );
    if (auth.currentUser?.uid != uid) {
      throw StateError('Account changed. Sign in again.');
    }
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> signOut() async => (await _auth()).signOut();
}

class LocalVaultProofRequired implements Exception {
  final String username;
  const LocalVaultProofRequired(this.username);
  @override
  String toString() =>
      'Enter the previous local password for "$username" to attach its saved data. Your Firebase password can be different.';
}

class MigrationEmailRequired implements Exception {
  const MigrationEmailRequired();
  @override
  String toString() =>
      'This older account has no email. Enter an email you own to migrate it.';
}

class MigrationPasswordRequired implements Exception {
  const MigrationPasswordRequired();
  @override
  String toString() =>
      'Your old local password was verified, but Firebase requires a stronger password. Choose a new Firebase password; your saved vault stays unchanged until migration completes.';
}

class FirebaseEmailVerificationRequired implements Exception {
  const FirebaseEmailVerificationRequired();
  @override
  String toString() =>
      'Verify your email using the Firebase email, then sign in again. You can resend verification below.';
}

/// Firebase credentials are authoritative. SQLite retains the original vault key.
class FirebaseAccountService {
  static final instance = FirebaseAccountService();
  final AccountAuthBackend backend;
  final AppDatabase database;
  FirebaseAccountService({AccountAuthBackend? backend, AppDatabase? database})
    : backend = backend ?? FirebaseAccountBackend(),
      database = database ?? AppDatabase.instance;

  void _check(FirebaseAccount account) {
    if (backend.current?.uid != account.uid ||
        backend.current?.email != account.email) {
      throw StateError('Authentication changed. Sign in again.');
    }
  }

  Future<Map<String, Object?>?> _local(String identifier) async {
    final db = await database.database;
    final rows = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
      whereArgs: [identifier.trim(), identifier.trim()],
    );
    if (rows.length > 1) {
      throw StateError(
        'This identifier matches two saved accounts. Use the account’s distinct username.',
      );
    }
    return rows.isEmpty ? null : rows.single;
  }

  Future<String> signIn(
    String identifier,
    String password, {
    String? legacyPassword,
    String? migrationEmail,
    String? migrationPassword,
  }) async {
    final local = await _local(identifier);
    final username = local?['username'] as String?;
    final binding = username == null
        ? null
        : await database.firebaseIdentity(username);
    final savedEmail =
        binding?['email'] as String? ?? local?['email'] as String?;
    final email =
        (savedEmail?.isNotEmpty == true
                ? savedEmail!
                : migrationEmail ?? identifier)
            .trim()
            .toLowerCase();
    if (!PasswordValidator.isValidEmail(email)) {
      throw const MigrationEmailRequired();
    }
    if (migrationPassword != null &&
        !PasswordValidator.validate(migrationPassword).isValid) {
      throw const MigrationPasswordRequired();
    }
    final firebasePassword = migrationPassword ?? password;
    final localProof =
        local != null &&
        binding == null &&
        await database.authenticateUser(username!, legacyPassword ?? password);
    FirebaseAccount account;
    var created = false;
    try {
      account = await backend.signIn(email, firebasePassword);
    } on FirebaseAuthException catch (error) {
      if (binding != null ||
          !localProof ||
          !{
            'invalid-credential',
            'wrong-password',
            'user-not-found',
            'invalid-login-credentials',
          }.contains(error.code)) {
        rethrow;
      }
      // Only a verified legacy password can bootstrap a missing Firebase account.
      // create() never updates an existing Firebase account's credentials.
      try {
        account = await backend.create(email, firebasePassword);
        created = true;
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'weak-password') {
          throw const MigrationPasswordRequired();
        }
        if (createError.code == 'email-already-in-use') {
          throw StateError(
            'This email already has a Firebase account. Use its password or Continue with Google, then provide the old local password when asked. Reset email changes only the Firebase password.',
          );
        }
        rethrow;
      }
    }
    _check(account);
    if (account.email.toLowerCase() != email) {
      throw StateError('Firebase returned a different email.');
    }
    if (binding != null && binding['firebase_uid'] != account.uid) {
      throw StateError('Firebase identity does not match this saved vault.');
    }
    if (local != null && binding == null && !localProof) {
      throw LocalVaultProofRequired(username!);
    }
    if (!account.emailVerified) {
      // Keep legacy credentials intact until email ownership is established.
      if (created) await backend.sendVerification();
      throw const FirebaseEmailVerificationRequired();
    }
    final owner = await database.firebaseUsernameForUid(account.uid);
    if (owner != null && username != null && owner != username) {
      throw StateError(
        'This Firebase account is already attached to another saved vault. No data was moved.',
      );
    }
    final target = owner ?? username ?? email;
    await database.attachFirebaseIdentity(
      username: target,
      uid: account.uid,
      email: email,
      provider: 'password',
      expectedLegacyHash: binding == null
          ? (local?['password_hash'] as String?)
          : null,
      checkSession: () => _check(account),
    );
    return target;
  }

  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    final cleanName = username.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty || !PasswordValidator.isValidEmail(cleanEmail)) {
      throw StateError('Enter a username and valid email.');
    }
    final validation = PasswordValidator.validate(password);
    if (!validation.isValid) {
      throw StateError(validation.missingRequirements.join('\n'));
    }
    if (await _local(cleanName) != null || await _local(cleanEmail) != null) {
      throw StateError(
        'Username or email already exists locally. Sign in to migrate the existing vault.',
      );
    }
    final account = await backend.create(cleanEmail, password);
    _check(account);
    await database.attachFirebaseIdentity(
      username: cleanName,
      uid: account.uid,
      email: cleanEmail,
      provider: 'password',
      checkSession: () => _check(account),
    );
    if (!account.emailVerified) {
      await backend.sendVerification();
      throw const FirebaseEmailVerificationRequired();
    }
    return cleanName;
  }

  /// Used after Firebase Google authentication; no account is linked by email alone.
  Future<String> acceptGoogle(
    FirebaseAccount account, {
    String? localPassword,
    bool localUnlockProven = false,
    bool historicGoogleVault = false,
  }) async {
    _check(account);
    if (!account.emailVerified) throw const FirebaseEmailVerificationRequired();
    final owner = await database.firebaseUsernameForUid(account.uid);
    final local = owner == null
        ? await _local(account.email)
        : await _local(owner);
    final username = owner ?? (local?['username'] as String?) ?? account.email;
    final binding = await database.firebaseIdentity(username);
    if (binding != null && binding['firebase_uid'] != account.uid) {
      throw StateError('This vault belongs to another Firebase identity.');
    }
    final legacyProof =
        localPassword != null &&
        await database.authenticateUser(username, localPassword);
    if (local != null &&
        binding == null &&
        !legacyProof &&
        !localUnlockProven &&
        !historicGoogleVault) {
      throw LocalVaultProofRequired(username);
    }
    await database.attachFirebaseIdentity(
      username: username,
      uid: account.uid,
      email: account.email,
      provider: account.providers.contains('password') ? 'password' : 'google',
      expectedLegacyHash: binding == null
          ? (local?['password_hash'] as String?)
          : null,
      checkSession: () => _check(account),
    );
    return username;
  }

  Future<void> resendVerification() => backend.sendVerification();

  Future<void> sendPasswordReset(String identifier) async {
    final local = await _local(identifier);
    final email = (local?['email'] as String? ?? identifier)
        .trim()
        .toLowerCase();
    if (!PasswordValidator.isValidEmail(email)) {
      throw StateError('Enter your Firebase account email.');
    }
    try {
      await backend.sendReset(email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') {
        rethrow; // Same success message prevents account enumeration.
      }
    }
  }

  Future<void> changePassword(
    String username,
    String oldPassword,
    String newPassword,
  ) async {
    final validation = PasswordValidator.validate(newPassword);
    if (!validation.isValid) {
      throw StateError(validation.missingRequirements.join('\n'));
    }
    final identity = await database.firebaseIdentity(username);
    if (identity == null) {
      throw StateError(
        'Sign out and sign in with your local password to migrate this account first.',
      );
    }
    await backend.changePassword(
      identity['firebase_uid'] as String,
      identity['email'] as String,
      oldPassword,
      newPassword,
    );
  }
}
