import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suara_surabaya_admin/core/auth/auth_service.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';

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

  // --- STATE ---
  AuthStatus _status = AuthStatus.Uninitialized;
  User? _firebaseUser;
  UserModel? _userModel;

  // --- GOOGLE SIGN IN CONFIG ---
  late GoogleSignIn _googleSignInAllPlatforms;
  static const _storage = FlutterSecureStorage();

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  bool get isAuthenticated => _status == AuthStatus.Authenticated;

  AuthenticationProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  }) : _authService = authService,
       _firestoreService = firestoreService {
    _initGoogleSignIn();
    _initialize();
  }

  void _initGoogleSignIn() {
    if (!kIsWeb) {
      _googleSignInAllPlatforms = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
          clientSecret: dotenv.env['GOOGLE_CLIENT_SECRET'],
          redirectPort: 8000,
          scopes: ['email', 'profile', 'openid'],
          saveAccessToken: (token) async {
            await _storage.write(key: 'google_access_token', value: token);
          },
          retrieveAccessToken: () async {
            return await _storage.read(key: 'google_access_token');
          },
          deleteAccessToken: () async {
            await _storage.delete(key: 'google_access_token');
          },
        ),
      );
    }
  }

  void _initialize() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
    _onAuthStateChanged(_authService.currentUser);
  }

  // --- LISTENER STATUS AUTH (GATEKEEPER UTAMA) ---
// --- LISTENER STATUS AUTH (GATEKEEPER UTAMA) ---
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.Unauthenticated;
      _firebaseUser = null;
      _userModel = null;
    } else {
      _firebaseUser = user;
      try {
        // 1. Force Refresh Token
        // Kita ambil String mentahnya sekalian
        String rawToken = (await user.getIdToken(true))!;
        
        // 2. Cek Claims (Hybrid: Coba Plugin dulu, kalau null pakai Manual Decode)
        bool isAdminClaim = false;
        
        try {
          final idTokenResult = await user.getIdTokenResult();
          final claimValue = idTokenResult.claims?['admin'];
          isAdminClaim = (claimValue == true || claimValue == 'true');
        } catch (_) {}

        // --- FIX KHUSUS WINDOWS: DECODE MANUAL JIKA PLUGIN GAGAL ---
        if (!isAdminClaim) {
          print("⚠️ Plugin gagal baca claims, mencoba decode manual...");
          try {
            Map<String, dynamic> payload = _parseJwt(rawToken);
            print("🕵️‍♂️ MANUAL DECODE PAYLOAD: $payload");
            if (payload['admin'] == true) {
              isAdminClaim = true;
              print("✅ Manual Decode: Admin Claim Ditemukan!");
            }
          } catch (e) {
            print("Gagal decode manual: $e");
          }
        }
        // -----------------------------------------------------------

        // 3. Ambil Profil Firestore
        _userModel = await _firestoreService.getUser(user.uid);
        
        // --- LOGIKA GATEKEEPER ---
        if (_userModel == null) {
           print("⛔ Gatekeeper: User ID ${user.uid} tidak ditemukan di database.");
           if (_status != AuthStatus.Authenticating) await signOut();
           return;
        } 
        else if (_userModel!.status == false) {
           print("⛔ Gatekeeper: User dinonaktifkan (Banned).");
           await signOut();
           return;
        }
        else if (!isAdminClaim) {
           print("⛔ Gatekeeper: TOKEN VALID TAPI TIDAK PUNYA 'ADMIN' CLAIM.");
           await signOut();
           return;
        }
        else if (_userModel!.role != 'Admin' && _userModel!.role != 'SuperAdmin') {
           print("⛔ Gatekeeper: Data Firestore tidak konsisten.");
           await signOut();
           return;
        }

        _status = AuthStatus.Authenticated;
      } catch (e) {
        print("Error checking auth state: $e");
        _status = AuthStatus.Unauthenticated;
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  // --- LOGIN EMAIL ---
  Future<String?> signIn(String email, String password) async {
    _setState(AuthStatus.Authenticating);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // _onAuthStateChanged akan menangani verifikasi claim selanjutnya
      return null;
    } on FirebaseAuthException catch (e) {
      _setState(AuthStatus.Unauthenticated);
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid.';
      } else {
        return 'Error: ${e.message}';
      }
    } catch (e) {
      _setState(AuthStatus.Unauthenticated);
      return 'Terjadi kesalahan sistem.';
    }
  }

  // --- REGISTER EMAIL (HARUS LEWAT CLOUD FUNCTION) ---
  // PENTING: Register manual lewat Client SDK tidak bisa memberi Custom Claim.
  // Jadi fungsi ini sebenarnya HANYA membuat user "Calon Admin" yang belum aktif.
  // Dia harus di-approve/promote oleh Super Admin lain agar dapat claim.
  Future<bool> signUp(String email, String password, String name) async {
    _setState(AuthStatus.Authenticating);
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );

      if (credential?.user != null) {
        UserModel newUser = UserModel(
          id: credential!.user!.uid,
          email: email,
          nama: name,
          username: name,
          role: 'User', // DEFAULT 'USER', BUKAN ADMIN
          hakAkses: {}, // Kosong
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

        await _firestoreService.setUserProfile(newUser);
        await _authService.signOut();

        // Disini harusnya return pesan: "Akun berhasil dibuat. Minta Super Admin untuk mengaktifkan akses Anda."
        _setState(AuthStatus.Unauthenticated);
        return true;
      }
      return false;
    } catch (e) {
      _setState(AuthStatus.Unauthenticated);
      return false;
    }
  }

  // --- GOOGLE SIGN IN ---
  Future<String?> signInWithGoogle() async {
    _setState(AuthStatus.Authenticating);
    UserCredential? userCredential;

    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final credentials = await _googleSignInAllPlatforms.signIn();
        if (credentials == null) {
          _setState(AuthStatus.Unauthenticated);
          return "Login Google dibatalkan.";
        }
        final googleAuth = GoogleAuthProvider.credential(
          accessToken: credentials.accessToken,
          idToken: credentials.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(googleAuth);
      }

      if (userCredential.user != null) {
        // --- FIX KHUSUS WINDOWS DI SINI JUGA ---
        String rawToken = (await userCredential.user!.getIdToken(true))!;
        bool isAdminClaim = false;

        // Coba cara normal
        try {
          final idTokenResult = await userCredential.user!.getIdTokenResult();
          final claimValue = idTokenResult.claims?['admin'];
          isAdminClaim = (claimValue == true || claimValue == 'true');
        } catch (_) {}

        // Fallback cara manual
        if (!isAdminClaim) {
           try {
            Map<String, dynamic> payload = _parseJwt(rawToken);
            if (payload['admin'] == true) isAdminClaim = true;
          } catch (_) {}
        }
        // ----------------------------------------

        if (!isAdminClaim) {
           await signOut();
           return "Akses ditolak. Akun Google ini tidak memiliki izin Admin.";
        }

        final doc = await _firestoreService.getUser(userCredential.user!.uid);
        if (doc == null || !doc.status) {
          await signOut();
          return "Akun tidak valid atau dinonaktifkan.";
        }
      }

      return null;

    } catch (e) {
      _setState(AuthStatus.Unauthenticated);
      if (e.toString().contains('popup-closed-by-user')) {
        return "Login dibatalkan.";
      }
      return "Gagal login: $e";
    }
  }

  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0: break;
      case 1: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignInAllPlatforms.signOut();
      } catch (_) {}
    }
    await _authService.signOut();
    _setState(AuthStatus.Unauthenticated);
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setState(AuthStatus.Authenticating);
    String? errorMessage;
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password')
        errorMessage = 'Password lama salah.';
      else if (e.code == 'weak-password')
        errorMessage = 'Password baru terlalu lemah.';
      else
        errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Terjadi kesalahan.';
    }
    _setState(AuthStatus.Authenticated);
    return errorMessage;
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
