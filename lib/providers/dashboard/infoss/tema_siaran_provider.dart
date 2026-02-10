import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/tema_siaran_model.dart';

enum TemaSiaranViewState { Idle, Busy, LoadingMore }

class TemaSiaranProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  // Hapus stream subscription global
  // StreamSubscription? _streamSubscription; 

  List<TemaSiaranModel> _temas = [];
  
  // State Pagination & Search
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false; 

  String _searchField = 'Nama Tema';
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _showContinueSearchButton = false;

  TemaSiaranViewState _state = TemaSiaranViewState.Busy;
  String? _errorMessage;

  List<TemaSiaranModel> get temas => _temas;
  TemaSiaranViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get showContinueSearchButton => _showContinueSearchButton;

  TemaSiaranProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    // Load data dipanggil dari UI via initState -> loadInitialData
  }

  // --- INITIAL LOAD ---
  void loadInitialData() {
    _searchQuery = '';
    _searchField = 'Nama Tema';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false; 
    
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    _temas = [];
    _lastDocument = null;
    _hasMoreData = true;

    _fetchNormalBatch(false);
  }

  // --- SEARCH & PAGINATION ---
  Future<void> searchTemaSiaran({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    _isSearching = searchQuery.isNotEmpty;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(TemaSiaranViewState.LoadingMore);
    } else {
      _setState(TemaSiaranViewState.Busy);
      _temas = [];
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
      _errorMessage = "Gagal memuat data: $e";
    }
    _setState(TemaSiaranViewState.Idle);
  }

  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (!_isUsingFilter) {
      snapshot = await _firestoreService.getAllTemaSiaranBatch(
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    } else {
      snapshot = await _firestoreService.getTemaSiaranBatch(
        startDate: _startDate,
        endDate: _endDate,
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
      if (!isContinuing) _setState(TemaSiaranViewState.Idle);
      return;
    }

    if (snapshot.docs.length < limit) {
      _hasMoreData = false;
    }

    _lastDocument = snapshot.docs.last;
    final newItems = snapshot.docs.map((doc) => TemaSiaranModel.fromFirestore(doc, null)).toList();

    if (isContinuing) {
      _temas.addAll(newItems);
    } else {
      _temas = newItems;
    }
    notifyListeners();
  }

  Future<void> _scanDataByBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimitPerCycle = 200;
    const int batchSize = 50;

    int docsScannedInThisCycle = 0;
    List<TemaSiaranModel> newItems = [];

    while (_temas.length < targetResults && docsScannedInThisCycle < scanLimitPerCycle && _hasMoreData) {
      final snapshot = await _firestoreService.getTemaSiaranBatch(
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
        final item = TemaSiaranModel.fromFirestore(doc, null);
        bool isMatch = false;

        if (_searchField == 'Nama Tema') {
          if (item.namaTema.toLowerCase().contains(_searchQuery.toLowerCase())) {
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
      _temas.addAll(newItems);
    } else {
      _temas = newItems;
    }

    if (docsScannedInThisCycle >= scanLimitPerCycle && _temas.length < targetResults && _hasMoreData) {
      _showContinueSearchButton = true;
    } else {
      _showContinueSearchButton = false;
    }
  }

  void continueSearch() {
    searchTemaSiaran(
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

  // --- CRUD ---

  Future<bool> addTemaSiaran(TemaSiaranModel tema) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      // Gunakan method with ID return
      final newId = await _firestoreService.addTemaSiaranWithIdReturn(tema);
      
      final newModel = tema.copyWith(id: newId);
      _temas.insert(0, newModel); // Insert ke paling atas
      
      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> updateTemaSiaran(TemaSiaranModel tema) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      await _firestoreService.updateTemaSiaran(tema);
      
      final index = _temas.indexWhere((t) => t.id == tema.id);
      if (index != -1) {
        _temas[index] = tema;
      }

      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteTemaSiaran(String temaId) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      await _firestoreService.deleteTemaSiaran(temaId);
      _temas.removeWhere((t) => t.id == temaId);
      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> setAsDefault(String temaId) async {
    try {
      await _firestoreService.setTemaSiaranAsDefault(temaId);
      
      // Update lokal: Loop semua tema, set isDefault false kecuali yang dipilih
      for (int i = 0; i < _temas.length; i++) {
        if (_temas[i].id == temaId) {
          _temas[i] = _temas[i].copyWith(isDefault: true);
        } else if (_temas[i].isDefault) {
          _temas[i] = _temas[i].copyWith(isDefault: false);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengatur default: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  void _setState(TemaSiaranViewState newState) {
    _state = newState;
    notifyListeners();
  }
}