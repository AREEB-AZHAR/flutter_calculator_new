/// Prevent an older asynchronous logout from signing out a new login.
class AuthSessionBarrier {
  static Future<void> pendingSignOut = Future.value();
}
