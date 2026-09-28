import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String salt, String expectedHash) {
    final calculatedHash = hashPassword(password, salt);
    return calculatedHash == expectedHash;
  }
}
