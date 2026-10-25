import 'package:firebase_auth/firebase_auth.dart';
import 'package:balance_tracker/services/firebase_account_service.dart';

class FakeAccountBackend implements AccountAuthBackend {
  final accounts = <String, FirebaseAccount>{};
  final passwords = <String, String>{};
  @override
  FirebaseAccount? current;
  int creates = 0;
  int verifications = 0;
  String? resetEmail;
  bool offline = false;
  bool verifyOnCreate = false;
  bool enforceMinimumPassword = false;
  Future<void> Function()? afterSignIn;
  String? resetError;
  void seed(
    String email,
    String password, {
    String uid = 'uid-alice',
    bool verified = true,
    Set<String> providers = const {'password'},
  }) {
    accounts[email] = FirebaseAccount(uid, email, verified, providers);
    passwords[email] = password;
  }

  void network() {
    if (offline) throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  Future<FirebaseAccount> signIn(String email, String password) async {
    network();
    if (passwords[email] != password || accounts[email] == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    current = accounts[email];
    final result = current!;
    await afterSignIn?.call();
    return result;
  }

  @override
  Future<FirebaseAccount> create(String email, String password) async {
    network();
    creates++;
    if (enforceMinimumPassword && password.length < 6) {
      throw FirebaseAuthException(code: 'weak-password');
    }
    if (accounts.containsKey(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    seed(email, password, verified: verifyOnCreate, uid: 'new-$email');
    return current = accounts[email]!;
  }

  @override
  Future<void> sendVerification() async {
    network();
    verifications++;
  }

  @override
  Future<void> sendReset(String email) async {
    network();
    if (resetError != null) throw FirebaseAuthException(code: resetError!);
    resetEmail = email;
  }

  @override
  Future<void> changePassword(
    String uid,
    String email,
    String oldPassword,
    String newPassword,
  ) async {
    network();
    if (current?.uid != uid || passwords[email] != oldPassword) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    passwords[email] = newPassword;
  }

  @override
  Future<void> signOut() async {
    current = null;
  }
}
