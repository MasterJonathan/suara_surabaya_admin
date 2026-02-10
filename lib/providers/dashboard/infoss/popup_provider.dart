import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/popup_model.dart';

enum PopUpViewState { Idle, Busy, LoadingMore }

class PopUpProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  // Hapus stream subscription
  // StreamSubscription? _streamSubscription;

  List<PopUpModel> _popups = [];
  
  // State Pagination & Search
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false; 

  String _searchField = 'Nama PopUp';
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _showContinueSearchButton = false;

  PopUpViewState _state = PopUpViewState.Busy;
  String? _errorMessage;

  List<PopUpModel> get popups => _popups;
  PopUpViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get showContinueSearchButton => _showContinueSearchButton;

  PopUpProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
     // Load Initial Data dipanggil dari UI
  }

  // --- INITIAL LOAD ---
  void loadInitialData() {
    _searchQuery = '';
    _searchField = 'Nama PopUp';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false; 
    
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    _popups = [];
    _lastDocument = null;
    _hasMoreData = true;

    _fetchNormalBatch(false);
  }

  // --- SEARCH & PAGINATION ---
  Future<void> searchPopUps({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    _isSearching = searchQuery.isNotEmpty;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(PopUpViewState.LoadingMore);
    } else {
      _setState(PopUpViewState.Busy);
      _popups = [];
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
        await _scanDataByBatch(isContinuing);
      }
    } catch (e) {
      print("❌ [PopUpProvider] Error searching: $e");
      _errorMessage = "Terjadi kesalahan saat memuat data.";
    }
    _setState(PopUpViewState.Idle);
  }

  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      if (!_isUsingFilter) {
        snapshot = await _firestoreService.getAllPopUpBatch(
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      } else {
        snapshot = await _firestoreService.getPopUpBatch(
          startDate: _startDate,
          endDate: _endDate,
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      }

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        if (!isContinuing) _setState(PopUpViewState.Idle);
        return;
      }

      if (snapshot.docs.length < limit) {
        _hasMoreData = false;
      }

      _lastDocument = snapshot.docs.last;
      final newItems = snapshot.docs.map((doc) => PopUpModel.fromFirestore(doc, null)).toList();

      if (isContinuing) {
        _popups.addAll(newItems);
      } else {
        _popups = newItems;
      }
    } catch (e) {
      print("❌ [PopUpProvider] Fetch Normal Error: $e");
    }
    notifyListeners();
  }

  Future<void> _scanDataByBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimitPerCycle = 200;
    const int batchSize = 50;

    int docsScannedInThisCycle = 0;
    List<PopUpModel> newItems = [];

    try {
      while (_popups.length < targetResults && docsScannedInThisCycle < scanLimitPerCycle && _hasMoreData) {
        final snapshot = await _firestoreService.getPopUpBatch(
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
        docsScannedInThisCycle += snapshot.docs.length;

        for (var doc in snapshot.docs) {
          final item = PopUpModel.fromFirestore(doc, null);
          bool isMatch = false;

          if (_searchField == 'Nama PopUp') {
            if (item.namaPopUp.toLowerCase().contains(_searchQuery.toLowerCase())) {
              isMatch = true;
            }
          } else if (_searchField == 'Oleh') {
            if (item.dipostingOleh.toLowerCase().contains(_searchQuery.toLowerCase())) {
              isMatch = true;
            }
          }

          if (isMatch) newItems.add(item);
        }
      }

      if (isContinuing) {
        _popups.addAll(newItems);
      } else {
        _popups = newItems;
      }

      if (docsScannedInThisCycle >= scanLimitPerCycle && _popups.length < targetResults && _hasMoreData) {
        _showContinueSearchButton = true;
      } else {
        _showContinueSearchButton = false;
      }
    } catch (e) {
       print("❌ [PopUpProvider] Scan Error: $e");
    }
  }

  void continueSearch() {
    searchPopUps(
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

  // --- CRUD (Optimistic) ---

  Future<bool> addPopUp(PopUpModel popUp) async {
    _setState(PopUpViewState.Busy);
    try {
      final newId = await _firestoreService.addPopUpWithIdReturn(popUp);
      
      final newModel = popUp.copyWith(id: newId);
      _popups.insert(0, newModel);
      
      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      print("❌ [PopUpProvider] Add Error: $e");
      _errorMessage = "Gagal menambah data.";
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  Future<bool> updatePopUp(PopUpModel popUp) async {
    _setState(PopUpViewState.Busy);
    try {
      await _firestoreService.updatePopUp(popUp);
      
      final index = _popups.indexWhere((p) => p.id == popUp.id);
      if (index != -1) {
        _popups[index] = popUp;
      }

      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      print("❌ [PopUpProvider] Update Error: $e");
      _errorMessage = "Gagal mengupdate data.";
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  Future<bool> deletePopUp(String popUpId) async {
    _setState(PopUpViewState.Busy);
    try {
      await _firestoreService.deletePopUp(popUpId);
      _popups.removeWhere((p) => p.id == popUpId);
      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      print("❌ [PopUpProvider] Delete Error: $e");
      _errorMessage = "Gagal menghapus data.";
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  void _setState(PopUpViewState newState) {
    _state = newState;
    notifyListeners();
  }
}