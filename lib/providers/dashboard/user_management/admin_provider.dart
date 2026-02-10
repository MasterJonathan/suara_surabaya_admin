import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Import Wajib
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/cloud_function_service.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';

enum AdminViewState { Idle, Busy }

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final CloudFunctionService _cloudFunctionService = CloudFunctionService();

  List<UserModel> _admins = [];
  
  // Pagination State
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  
  AdminViewState _state = AdminViewState.Busy;
  String? _errorMessage;

  List<UserModel> get admins => _admins;
  AdminViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;

  AdminProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // --- LOAD ADMIN LIST (Tetap Sama) ---
  Future<void> loadAdmins({bool refresh = false}) async {
    if (refresh) {
      _admins = [];
      _lastDocument = null;
      _hasMoreData = true;
      _state = AdminViewState.Busy;
      notifyListeners();
    }

    if (!_hasMoreData) return;

    try {
      final snapshot = await _firestoreService.getAdminsBatch(
        limit: 20,
        startAfterDoc: _lastDocument,
      );

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
      } else {
        _lastDocument = snapshot.docs.last;
        final newAdmins = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc, null))
            .toList();
        _admins.addAll(newAdmins);
        if (snapshot.docs.length < 20) _hasMoreData = false;
      }
    } catch (e) {
      _errorMessage = "Gagal memuat admin: $e";
    }
    
    _state = AdminViewState.Idle;
    notifyListeners();
  }

  // --- CLOUD FUNCTION CALLER ---
  // Fungsi Helper untuk memanggil Cloud Function 'manageUserRole'
  Future<String?> _callManageRoleFunction({required String email, required String newRole}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('manageUserRole');
      
      await callable.call({
        'targetEmail': email,
        'newRole': newRole,
      });
      
      return null; // Sukses (Error null)
    } on FirebaseFunctionsException catch (e) {
      // Menangkap error spesifik dari Cloud Function (yang kita throw di index.js)
      return e.message ?? "Terjadi kesalahan pada server.";
    } catch (e) {
      return "Gagal terhubung ke server: $e";
    }
  }

// --- PROMOTE USER (UPDATED VIA SERVICE) ---
  Future<String?> promoteUserToAdmin(String email) async {
    _state = AdminViewState.Busy;
    notifyListeners();
    
    try {
      // Panggil lewat Wrapper Service
      await _cloudFunctionService.call('manageUserRole', {
        'targetEmail': email,
        'newRole': 'Admin',
      });

      // Sukses
      await loadAdmins(refresh: true);
      _state = AdminViewState.Idle;
      notifyListeners();
      return null;

    } catch (e) {
      // Error String ditangkap dari Service
      _state = AdminViewState.Idle;
      notifyListeners();
      return e.toString();
    }
  }

  // --- DEMOTE USER (UPDATED VIA SERVICE) ---
  Future<String?> demoteToUser(UserModel adminUser) async {
    _state = AdminViewState.Busy;
    notifyListeners();

    try {
      // Panggil lewat Wrapper Service
      await _cloudFunctionService.call('manageUserRole', {
        'targetEmail': adminUser.email, // Pastikan backend pakai 'targetEmail'
        'newRole': 'User',
      });

      // Sukses - Hapus lokal
      _admins.removeWhere((u) => u.id == adminUser.id);
      _state = AdminViewState.Idle;
      notifyListeners();
      return null;

    } catch (e) {
      _state = AdminViewState.Idle;
      notifyListeners();
      return e.toString();
    }
  }

  // --- UPDATE HAK AKSES (Tetap Client Side / Direct DB) ---
  // Karena hak akses (read/write modul) disimpan di Firestore saja,
  // tidak perlu lewat Cloud Function yang berat.
  Future<bool> updateAdminPermissions(String userId, Map<String, String> newPermissions) async {
    try {
      await _firestoreService.updateUserPartial(userId, {
        'hakAkses': newPermissions
      });
      
      final index = _admins.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _admins[index] = _admins[index].copyWith(hakAkses: newPermissions);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}