import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/banner_model.dart';

enum BannerViewState { Idle, Busy, LoadingMore }

class BannerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  // Hapus stream subscription
  // StreamSubscription? _streamSubscription;

  List<BannerTopModel> _banners = [];
  
  // State Pagination & Search
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false; 

  String _searchField = 'Nama Banner';
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _showContinueSearchButton = false;

  BannerViewState _state = BannerViewState.Busy;
  String? _errorMessage;

  List<BannerTopModel> get banners => _banners;
  BannerViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get showContinueSearchButton => _showContinueSearchButton;

  BannerProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    // Load Initial Data dipanggil dari UI via initState
  }

  // --- INITIAL LOAD ---
  void loadInitialData() {
    _searchQuery = '';
    _searchField = 'Nama Banner';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false; 
    
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    _banners = [];
    _lastDocument = null;
    _hasMoreData = true;

    _fetchNormalBatch(false);
  }

  // --- SEARCH & PAGINATION ---
  Future<void> searchBanners({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    _isSearching = searchQuery.isNotEmpty;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(BannerViewState.LoadingMore);
    } else {
      _setState(BannerViewState.Busy);
      _banners = [];
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
      // LOG ERROR ONLY
      print("❌ [BannerProvider] Error searching: $e");
      _errorMessage = "Terjadi kesalahan saat memuat data.";
    }
    _setState(BannerViewState.Idle);
  }

  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      if (!_isUsingFilter) {
        snapshot = await _firestoreService.getAllBannerBatch(
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      } else {
        snapshot = await _firestoreService.getBannerBatch(
          startDate: _startDate,
          endDate: _endDate,
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      }

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        if (!isContinuing) _setState(BannerViewState.Idle);
        return;
      }

      if (snapshot.docs.length < limit) {
        _hasMoreData = false;
      }

      _lastDocument = snapshot.docs.last;
      final newItems = snapshot.docs.map((doc) => BannerTopModel.fromFirestore(doc, null)).toList();

      if (isContinuing) {
        _banners.addAll(newItems);
      } else {
        _banners = newItems;
      }
    } catch (e) {
      print("❌ [BannerProvider] Fetch Normal Error: $e");
    }
    notifyListeners();
  }

  Future<void> _scanDataByBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimitPerCycle = 200;
    const int batchSize = 50;

    int docsScannedInThisCycle = 0;
    List<BannerTopModel> newItems = [];

    try {
      while (_banners.length < targetResults && docsScannedInThisCycle < scanLimitPerCycle && _hasMoreData) {
        final snapshot = await _firestoreService.getBannerBatch(
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
          final item = BannerTopModel.fromFirestore(doc, null);
          bool isMatch = false;

          if (_searchField == 'Nama Banner') {
            if (item.namaBanner.toLowerCase().contains(_searchQuery.toLowerCase())) {
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
        _banners.addAll(newItems);
      } else {
        _banners = newItems;
      }

      if (docsScannedInThisCycle >= scanLimitPerCycle && _banners.length < targetResults && _hasMoreData) {
        _showContinueSearchButton = true;
      } else {
        _showContinueSearchButton = false;
      }
    } catch (e) {
       print("❌ [BannerProvider] Scan Error: $e");
    }
  }

  void continueSearch() {
    searchBanners(
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

  // --- CRUD (Optimistic Update) ---

  Future<bool> addBanner(BannerTopModel banner) async {
    _setState(BannerViewState.Busy);
    try {
      // Add ke DB dan dapatkan ID
      final newId = await _firestoreService.addBannerWithIdReturn(banner);
      
      // Update Lokal langsung
      final newModel = banner.copyWith(id: newId);
      _banners.insert(0, newModel);
      
      _setState(BannerViewState.Idle);
      return true;
    } catch (e) {
      print("❌ [BannerProvider] Add Error: $e");
      _errorMessage = "Gagal menambah banner.";
      _setState(BannerViewState.Idle);
      return false;
    }
  }

  Future<bool> updateBanner(BannerTopModel banner) async {
    _setState(BannerViewState.Busy);
    try {
      await _firestoreService.updateBanner(banner);
      
      // Update Lokal
      final index = _banners.indexWhere((b) => b.id == banner.id);
      if (index != -1) {
        _banners[index] = banner;
      }

      _setState(BannerViewState.Idle);
      return true;
    } catch (e) {
       print("❌ [BannerProvider] Update Error: $e");
      _errorMessage = "Gagal mengupdate banner.";
      _setState(BannerViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteBanner(String bannerId) async {
    _setState(BannerViewState.Busy);
    try {
      await _firestoreService.deleteBanner(bannerId);
      
      // Update Lokal
      _banners.removeWhere((b) => b.id == bannerId);
      
      _setState(BannerViewState.Idle);
      return true;
    } catch (e) {
       print("❌ [BannerProvider] Delete Error: $e");
      _errorMessage = "Gagal menghapus banner.";
      _setState(BannerViewState.Idle);
      return false;
    }
  }

  void _setState(BannerViewState newState) {
    _state = newState;
    notifyListeners();
  }
}