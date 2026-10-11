import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception carrying a user-friendly Indonesian message.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Wraps [FirebaseAuth] operations and translates Firebase errors into
/// [AuthException] with friendly Indonesian messages.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  /// Emits the current user (or `null`) whenever the auth state changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  /// Signs in with [email] and [password].
  ///
  /// Throws [AuthException] with an Indonesian message on failure.
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          throw const AuthException(
            'Email atau kata sandi salah. Periksa kembali dan coba lagi.',
          );
        case 'invalid-email':
          throw const AuthException('Format email tidak valid.');
        case 'user-disabled':
          throw const AuthException(
            'Akun ini telah dinonaktifkan. Hubungi dukungan.',
          );
        case 'too-many-requests':
          throw const AuthException(
            'Terlalu banyak percobaan. Coba lagi nanti.',
          );
        default:
          throw const AuthException(
            'Terjadi kesalahan. Periksa koneksi internet dan coba lagi.',
          );
      }
    }
  }

  /// Creates a new account with [email] and [password].
  ///
  /// Throws [AuthException] with an Indonesian message on failure.
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthException(
            'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.',
          );
        case 'weak-password':
          throw const AuthException(
            'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
          );
        case 'invalid-email':
          throw const AuthException('Format email tidak valid.');
        default:
          throw const AuthException(
            'Terjadi kesalahan. Periksa koneksi internet dan coba lagi.',
          );
      }
    }
  }

  /// Signs the current user out.
  Future<void> signOut() => _auth.signOut();
}
