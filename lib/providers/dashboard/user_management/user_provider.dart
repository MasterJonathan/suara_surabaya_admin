import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';

enum UserViewState { Idle, Busy, LoadingMore }

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  StreamSubscription? _liveUserSubscription;
  List<UserModel> _users = [];
  
  bool _isLiveMode = false;

  // Pagination State
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false;

  String _searchField = 'Nama';
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 600));
  DateTime _endDate = DateTime.now();
  
  bool _showContinueSearchButton = false;

  UserViewState _state = UserViewState.Busy;
  String? _errorMessage;

  List<UserModel> get users => _users;
  UserViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get isLiveMode => _isLiveMode;
  bool get showContinueSearchButton => _showContinueSearchButton;

  UserProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // --- TOGGLE LIVE MODE ---
  void toggleLiveMode(bool value) {
    _isLiveMode = value;
    if (_isLiveMode) {
      _startLiveMonitoring();
    } else {
      _stopLiveMonitoring();
      loadInitialData();
    }
    notifyListeners();
  }

  void _startLiveMonitoring() {
    _state = UserViewState.Busy;
    _users = [];
    notifyListeners();
    _liveUserSubscription?.cancel();

    _liveUserSubscription = _firestoreService.getUsersLiveStream(limit: 50).listen((data) {
      _users = data;
      _state = UserViewState.Idle;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = "Live stream error: $error";
      _state = UserViewState.Idle;
      notifyListeners();
    });
  }

  void _stopLiveMonitoring() {
    _liveUserSubscription?.cancel();
    _liveUserSubscription = null;
  }

  // --- MANUAL LOAD ---
  void loadInitialData() {
    if (_isLiveMode) return;

    _searchQuery = '';
    _searchField = 'Nama';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false;
    
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    _users = [];
    _lastDocument = null;
    _hasMoreData = true;

    _fetchNormalBatch(false);
  }

  Future<void> searchUsers({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    if (_isLiveMode) return;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(UserViewState.LoadingMore);
    } else {
      _setState(UserViewState.Busy);
      _users = [];
      _lastDocument = null;
      _hasMoreData = true;
      _showContinueSearchButton = false;

      _searchField = searchField;
      _searchQuery = searchQuery;
      _startDate = startDate;
      _endDate = endDate;
      _isUsingFilter = true;
    }

    try {
      if (searchQuery.trim().isEmpty) {
        await _fetchNormalBatch(isContinuing);
      } else {
        await _scanUserBatch(isContinuing);
      }
    } catch (e) {
      _errorMessage = "Gagal memuat data: $e";
    }
    _setState(UserViewState.Idle);
  }

  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 20; // Load 20 items per batch
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (!_isUsingFilter) {
      snapshot = await _firestoreService.getAllUsersBatch(
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    } else {
      snapshot = await _firestoreService.getUsersBatch(
        startDate: _startDate,
        endDate: _endDate,
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
      if (!isContinuing) _setState(UserViewState.Idle);
      return;
    }

    if (snapshot.docs.length < limit) {
      _hasMoreData = false;
    } else {
      _hasMoreData = true; // Masih ada kemungkinan data berikutnya
    }

    _lastDocument = snapshot.docs.last;
    final newItems = snapshot.docs.map((doc) => UserModel.fromFirestore(doc, null)).toList();

    if (isContinuing) {
      _users.addAll(newItems);
    } else {
      _users = newItems;
    }
    notifyListeners();
  }

  Future<void> _scanUserBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimit = 200;
    const int batchSize = 50;
    int scanned = 0;
    List<UserModel> newItems = [];

    while (_users.length < targetResults && scanned < scanLimit && _hasMoreData) {
      final snapshot = await _firestoreService.getUsersBatch(
        startDate: _startDate,
        endDate: _endDate,
        limit: batchSize,
        startAfterDoc: _lastDocument,
      );

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        break;
      }

      _lastDocument = snapshot.docs.last;
      scanned += snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final item = UserModel.fromFirestore(doc, null);
        bool isMatch = false;
        final q = _searchQuery.toLowerCase();

        if (_searchField == 'Nama' && item.nama.toLowerCase().contains(q)) isMatch = true;
        if (_searchField == 'Email' && item.email.toLowerCase().contains(q)) isMatch = true;
        if (_searchField == 'Role' && item.role.toLowerCase().contains(q)) isMatch = true;

        if (isMatch) newItems.add(item);
      }
    }

    if (isContinuing) _users.addAll(newItems); else _users = newItems;
    
    _showContinueSearchButton = (scanned >= scanLimit && _users.length < targetResults && _hasMoreData);
  }

  void continueSearch() {
    searchUsers(
      searchField: _searchField,
      searchQuery: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      isContinuing: true,
    );
  }

  void resetSearch() {
    loadInitialData();
  }

  // --- CRUD UPDATES (REALTIME LOCAL) ---

  Future<bool> updateUserComplete(UserModel updatedUser) async {
    _setState(UserViewState.Busy);
    try {
      // 1. Update ke Firestore
      await _firestoreService.updateUser(updatedUser);
      
      // 2. Update Lokal List (Optimistic Update)
      final index = _users.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      _setState(UserViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(UserViewState.Idle);
      return false;
    }
  }

  Future<bool> updateUserPartial(String userId, Map<String, dynamic> data) async {
    try {
      // 1. Update Firestore
      await _firestoreService.updateUserPartial(userId, data);
      
      // 2. Update Lokal
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        UserModel user = _users[index];
        // Apply changes locally
        if (data.containsKey('status')) user = user.copyWith(status: data['status']);
        if (data.containsKey('role')) user = user.copyWith(role: data['role']);
        if (data.containsKey('nama')) user = user.copyWith(nama: data['nama']);
        
        _users[index] = user;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    _setState(UserViewState.Busy);
    try {
      await _firestoreService.deleteUser(userId);
      _users.removeWhere((u) => u.id == userId);
      _setState(UserViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(UserViewState.Idle);
      return false;
    }
  }

  void _setState(UserViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveUserSubscription?.cancel();
    super.dispose();
  }
}