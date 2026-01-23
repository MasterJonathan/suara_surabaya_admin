// lib/core/auth/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // ==== PERBAIKAN DI SINI ====
    // Blok try-catch dihapus agar error (spt 'invalid-credential')
    // bisa ditangani oleh AuthenticationProvider.
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // ==== PERBAIKAN DI SINI ====
    // Blok try-catch dihapus agar error (spt 'email-already-in-use')
    // bisa ditangani oleh AuthenticationProvider.
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // --- Fungsi di bawah ini Boleh Dibiarkan (sudah benar) ---

  Future<void> changePassword(String currentPassword, String newPassword) async {
    // Dapatkan pengguna yang sedang login
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Tidak ada pengguna yang login.");
    }

    // Buat kredensial dengan password lama untuk re-autentikasi
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      // Re-autentikasi pengguna untuk keamanan
      await user.reauthenticateWithCredential(cred);
      // Jika berhasil, baru ubah password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      // Tangani error seperti password lama yang salah, dll.
      print("Error saat mengubah password: ${e.code}");
      rethrow; // Lempar kembali error agar bisa ditangani di UI/Provider
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}