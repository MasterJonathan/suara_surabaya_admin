// lib/providers/authentication_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/auth/auth_service.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthStatus {
  Uninitialized,
  Authenticated,
  Authenticating,
  Unauthenticated,
}

class AuthenticationProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  late StreamSubscription<User?> _authSubscription;

  AuthStatus _status = AuthStatus.Uninitialized;
  User? _firebaseUser;
  UserModel? _userModel;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  bool get isAuthenticated => _status == AuthStatus.Authenticated;

  AuthenticationProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  }) : _authService = authService,
       _firestoreService = firestoreService {
    _initialize();
  }

  void _initialize() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
    _onAuthStateChanged(_authService.currentUser); // Periksa status awal
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.Unauthenticated;
      _firebaseUser = null;
      _userModel = null;
    } else {
      _firebaseUser = user;
      // Ambil data profil dari Firestore setelah login/register
      _userModel = await _firestoreService.getUser(user.uid);

      // Jika profil tidak ditemukan (misal user login dengan Google/provider lain pertama kali)
      // Anda bisa membuat profil default di sini.
      if (_userModel == null) {
        print(
          "Profil Firestore untuk user ${user.uid} tidak ditemukan. Mungkin perlu dibuatkan.",
        );
        // Untuk alur register, profil seharusnya sudah dibuat.
        // Ini lebih relevan untuk Social Login.
      }

      _status = AuthStatus.Authenticated;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

Future<String?> signIn(String email, String password) async {
  _setState(AuthStatus.Authenticating);
  try {
    await _authService.signInWithEmailAndPassword(email, password);
    // Jika berhasil, _onAuthStateChanged akan dipicu. Kembalikan null (tidak ada error).
    return null;
  } on FirebaseAuthException catch (e) { // Tangkap error spesifik dari Firebase Auth
    _setState(AuthStatus.Unauthenticated);
    
    // --- PERBAIKAN 2: Kembalikan pesan error yang lebih user-friendly ---
    if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
      return 'Email atau password yang Anda masukkan salah.';
    } else if (e.code == 'invalid-email') {
      return 'Format email tidak valid.';
    } else {
      // Untuk error lain yang tidak terduga
      return 'Terjadi kesalahan: ${e.message}';
    }
  } catch (e) {
    // Untuk error umum lainnya
    _setState(AuthStatus.Unauthenticated);
    return 'Terjadi kesalahan tidak dikenal. Silakan coba lagi.';
  }
}

  Future<bool> signUp(String email, String password, String name) async {
    _setState(AuthStatus.Authenticating);
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      if (credential?.user != null) {
        // --- INI BAGIAN PENTING UNTUK MEMBUAT PROFIL DI FIRESTORE ---
        UserModel newUser = UserModel(
          id: credential!.user!.uid, // Gunakan UID dari Auth sebagai ID dokumen
          email: email,
          nama: name,
          username: name,
          role: 'Admin',
          hakAkses: {
            'overview': 'write', // Akses penuh ke halaman overview/dashboard
            'profile': 'write', // Akses penuh untuk mengelola profil sendiri
          }, // Peran default untuk admin panel
          photoURL:
              'https://static.vecteezy.com/system/resources/previews/020/765/399/original/default-profile-account-unknown-icon-black-silhouette-free-vector.jpg',
          jumlahComment: 0,
          jumlahKontributor: 0,
          jumlahLike: 0,
          jumlahShare: 0,
          alamat: '',
          jenisKelamin: '',
          nomorHp: '',
          tanggalLahir: '',
          status: true,
          joinDate: DateTime.now(),
        );
        // Panggil service untuk menyimpan profil baru ini ke Firestore
        await _firestoreService.setUserProfile(newUser);
        // -------------------------------------------------------------

        // Setelah berhasil mendaftar dan membuat profil, langsung logout.
        await _authService.signOut();

        return true;
      }
      return false;
    } catch (e) {
      _setState(AuthStatus.Unauthenticated);
      print(e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _setState(AuthStatus.Unauthenticated);
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setState(AuthStatus.Authenticating); // Gunakan status ini sebagai 'Busy'
    String? errorMessage;
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } on FirebaseAuthException catch (e) {
      // Terjemahkan kode error Firebase menjadi pesan yang mudah dimengerti
      if (e.code == 'wrong-password') {
        errorMessage = 'Password lama yang Anda masukkan salah.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password baru terlalu lemah.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan tidak dikenal.';
    }

    _setState(AuthStatus.Authenticated); // Kembali ke status normal
    return errorMessage; // Kembalikan null jika berhasil, atau pesan error jika gagal
  }

  void _setState(AuthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
