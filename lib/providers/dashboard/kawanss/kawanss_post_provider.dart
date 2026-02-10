import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';

enum KawanssPostViewState { Idle, Busy, LoadingMore }

class KawanssPostProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

   // --- STREAM KHUSUS LIVE MODE ---
  StreamSubscription? _livePostSubscription; 
  StreamSubscription? _liveCommentSubscription; 
  

  List<KawanssModel> _posts = [];
  List<KawanssCommentModel> _comments = [];


  // --- STATE HYBRID ---
  bool _isLiveMode = false; // Default Manual Mode
  
  // --- STATE PAGINATION & SEARCH ---
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false; // False = Initial Load, True = Filter Tanggal Aktif
  
  String _searchField = 'Deskripsi'; // Default field pencarian
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  bool _showContinueSearchButton = false;
  // --------------------------------

   // --- STATE HYBRID COMMENTS (BARU) ---
  bool _isCommentLiveMode = false;
  DocumentSnapshot? _lastCommentDoc;
  bool _hasMoreComments = true;
  bool _isSearchingComments = false;
  bool _isUsingCommentFilter = false;

  String _commentSearchField = 'Komentar';
  String _commentSearchQuery = '';
  DateTime _commentStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _commentEndDate = DateTime.now();
  
  bool _showContinueCommentSearch = false;
  // ------------------------------------

  KawanssPostViewState _state = KawanssPostViewState.Busy;
  String? _errorMessage;

  // Getters
  List<KawanssModel> get posts => _posts;
  List<KawanssCommentModel> get comments => _comments;
  KawanssPostViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get hasMoreComments => _hasMoreComments; // Getter baru
  bool get isLiveMode => _isLiveMode;
  bool get isCommentLiveMode => _isCommentLiveMode; // Getter baru
  bool get showContinueCommentSearch => _showContinueCommentSearch;
  bool get isSearching => _isSearching;
  bool get showContinueSearchButton => _showContinueSearchButton;
  

  KawanssPostProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    // Jangan panggil loadInitialData di sini agar bisa dikontrol UI (via addPostFrameCallback)
    // Tapi _listenToComments tetap jalan karena stream terpisah
  }


  void toggleLiveMode(bool value) {
    _isLiveMode = value;
    if (_isLiveMode) {
      _startLiveMonitoring();
    } else {
      _stopLiveMonitoring();
      loadInitialData(); // Kembali ke pagination manual
    }
    notifyListeners();
  }

  void _startLiveMonitoring() {
    _state = KawanssPostViewState.Busy;
    _posts = [];
    notifyListeners();

    // Batalkan stream lama jika ada
    _livePostSubscription?.cancel();

    // Start Stream Realtime (Limit 50)
    _livePostSubscription = _firestoreService.getKawanssLiveStream(limit: 50).listen((data) {
      _posts = data;
      _state = KawanssPostViewState.Idle;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = "Live stream error: $error";
      _state = KawanssPostViewState.Idle;
      notifyListeners();
    });
  }

  void _stopLiveMonitoring() {
    _livePostSubscription?.cancel();
    _livePostSubscription = null;
  }

  // --- 1. LOAD INITIAL DATA ---
  void loadInitialData() {
    _searchQuery = '';
    _searchField = 'Deskripsi';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false; // Reset ke mode tanpa filter tanggal
    
    // Default tanggal untuk UI DatePicker
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    // Reset Data
    _posts = [];
    _lastDocument = null;
    _hasMoreData = true;

    // Panggil fetch batch normal tanpa filter tanggal
    _fetchNormalBatch(false);
  }

  // --- 2. SEARCH & PAGINATION LOGIC ---
  Future<void> searchPosts({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    _isSearching = searchQuery.isNotEmpty;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(KawanssPostViewState.LoadingMore);
    } else {
      _setState(KawanssPostViewState.Busy);
      _posts = [];
      _lastDocument = null;
      _hasMoreData = true;
      _showContinueSearchButton = false;

      // Simpan parameter filter
      _searchField = searchField;
      _searchQuery = searchQuery;
      _startDate = startDate;
      _endDate = endDate;
      
      // Jika user melakukan pencarian atau memilih tanggal, aktifkan mode filter
      _isUsingFilter = true;
    }

    try {
      // Jika Query Kosong -> Fetch Batch Normal (berdasarkan tanggal atau semua)
      if (searchQuery.trim().isEmpty) {
        await _fetchNormalBatch(isContinuing);
      } 
      // Jika Ada Query -> Lakukan Scan Client-Side
      else {
        await _scanDataByBatch(isContinuing);
      }
    } catch (e) {
      _errorMessage = "Gagal memuat data: $e";
    }
    _setState(KawanssPostViewState.Idle);
  }

  // --- FETCH NORMAL (Tanpa Keyword Search) ---
  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    // Jika load awal (tanpa filter), pakai getAllKawanssBatch
    if (!_isUsingFilter) {
      snapshot = await _firestoreService.getAllKawanssBatch(
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    } else {
      // Jika user pakai filter tanggal
      snapshot = await _firestoreService.getKawanssBatch(
        startDate: _startDate,
        endDate: _endDate,
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
      if (!isContinuing) _setState(KawanssPostViewState.Idle);
      return;
    }

    if (snapshot.docs.length < limit) {
      _hasMoreData = false;
    }

    _lastDocument = snapshot.docs.last;
    final newItems = snapshot.docs.map((doc) => KawanssModel.fromFirestore(doc, null)).toList();

    if (isContinuing) {
      _posts.addAll(newItems);
    } else {
      _posts = newItems;
    }
    notifyListeners();
  }

  // --- FETCH SCANNING (Dengan Keyword Search) ---
  Future<void> _scanDataByBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimitPerCycle = 200; // Baca max 200 doc per klik tombol
    const int batchSize = 50;

    int docsScannedInThisCycle = 0;
    List<KawanssModel> newItems = [];

    // Loop scanning
    while (_posts.length < targetResults && docsScannedInThisCycle < scanLimitPerCycle && _hasMoreData) {
      // Selalu gunakan filter tanggal saat scanning agar efisien
      final snapshot = await _firestoreService.getKawanssBatch(
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
        final post = KawanssModel.fromFirestore(doc, null);
        bool isMatch = false;

        // Logika Pencarian Client-Side
        if (_searchField == 'Deskripsi') {
          if ((post.deskripsi?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) || 
              (post.title?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase())) {
            isMatch = true;
          }
        } else if (_searchField == 'User') {
          if ((post.accountName?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase())) {
            isMatch = true;
          }
        }

        if (isMatch) newItems.add(post);
      }
    }

    if (isContinuing) {
      _posts.addAll(newItems);
    } else {
      _posts = newItems;
    }

    // Cek apakah perlu tombol "Lanjutkan Pencarian"
    if (docsScannedInThisCycle >= scanLimitPerCycle && _posts.length < targetResults && _hasMoreData) {
      _showContinueSearchButton = true;
    } else {
      _showContinueSearchButton = false;
    }
  }

  // --- 3. HELPER METHODS UNTUK PAGE ---
  void continueSearch() {
    searchPosts(
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

  // --- 4. CRUD OPERATIONS ---
  // Note: Kawan SS biasanya dibuat dari Mobile App, jadi Add jarang dipakai di Admin.
  // Tapi Update & Delete sering dipakai.

  Future<bool> updatePost(KawanssModel post) async {
    _setState(KawanssPostViewState.Busy);
    try {
      await _firestoreService.updateKawanss(post);
      
      // Update data lokal
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
      }
      
      _setState(KawanssPostViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssPostViewState.Idle);
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    _setState(KawanssPostViewState.Busy);
    try {
      await _firestoreService.deleteKawanss(postId);
      
      // Hapus dari list lokal
      _posts.removeWhere((p) => p.id == postId);
      
      _setState(KawanssPostViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssPostViewState.Idle);
      return false;
    }
  }




  // ===========================================================================
  // BAGIAN 2: COMMENTS (KODE BARU - HYBRID MODE)
  // ===========================================================================

  // --- TOGGLE LIVE MODE KOMENTAR ---
  void toggleCommentLiveMode(bool value) {
    _isCommentLiveMode = value;
    if (_isCommentLiveMode) {
      _startCommentLiveMonitoring();
    } else {
      _stopCommentLiveMonitoring();
      loadInitialComments(); // Kembali ke manual pagination
    }
    notifyListeners();
  }

  void _startCommentLiveMonitoring() {
    _state = KawanssPostViewState.Busy;
    _comments = [];
    notifyListeners();

    _liveCommentSubscription?.cancel();

    _liveCommentSubscription = _firestoreService.getKawanssCommentsLiveStream(limit: 50).listen((data) {
      _comments = data;
      _state = KawanssPostViewState.Idle;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = "Live comment stream error: $error";
      _state = KawanssPostViewState.Idle;
      notifyListeners();
    });
  }

  void _stopCommentLiveMonitoring() {
    _liveCommentSubscription?.cancel();
    _liveCommentSubscription = null;
  }

  // --- LOAD INITIAL COMMENTS (MANUAL) ---
  void loadInitialComments() {
    if (_isCommentLiveMode) return;

    _commentSearchQuery = '';
    _commentSearchField = 'Komentar';
    _showContinueCommentSearch = false;
    _isUsingCommentFilter = false;
    _errorMessage = null;
    
    _commentStartDate = DateTime.now().subtract(const Duration(days: 30));
    _commentEndDate = DateTime.now();

    _comments = [];
    _lastCommentDoc = null;
    _hasMoreComments = true;

    _fetchNormalCommentBatch(false);
  }

  // --- SEARCH & PAGINATION COMMENTS ---
  Future<void> searchComments({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    if (_isCommentLiveMode) return;

    if (isContinuing) {
      if (!_hasMoreComments) return;
      _setState(KawanssPostViewState.LoadingMore);
    } else {
      _setState(KawanssPostViewState.Busy);
      _comments = [];
      _lastCommentDoc = null;
      _hasMoreComments = true;
      _showContinueCommentSearch = false;

      _commentSearchField = searchField;
      _commentSearchQuery = searchQuery;
      _commentStartDate = startDate;
      _commentEndDate = endDate;
      _isUsingCommentFilter = true;
    }

    try {
      if (searchQuery.trim().isEmpty) {
        await _fetchNormalCommentBatch(isContinuing);
      } else {
        await _scanCommentBatch(isContinuing);
      }
    } catch (e) {
      _errorMessage = "Gagal memuat komentar: $e";
    }
    _setState(KawanssPostViewState.Idle);
  }

  Future<void> _fetchNormalCommentBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (!_isUsingCommentFilter) {
      snapshot = await _firestoreService.getAllKawanssCommentsBatch(
        limit: limit,
        startAfterDoc: _lastCommentDoc,
      );
    } else {
      snapshot = await _firestoreService.getKawanssCommentsBatch(
        startDate: _commentStartDate,
        endDate: _commentEndDate,
        limit: limit,
        startAfterDoc: _lastCommentDoc,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreComments = false;
      if (!isContinuing) _setState(KawanssPostViewState.Idle);
      return;
    }

    if (snapshot.docs.length < limit) _hasMoreComments = false;

    _lastCommentDoc = snapshot.docs.last;
    final newItems = snapshot.docs.map((doc) => KawanssCommentModel.fromFirestore(doc, null)).toList();

    if (isContinuing) {
      _comments.addAll(newItems);
    } else {
      _comments = newItems;
    }
    notifyListeners();
  }

  Future<void> _scanCommentBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimit = 200;
    const int batchSize = 50;
    int scanned = 0;
    List<KawanssCommentModel> newItems = [];

    while (_comments.length < targetResults && scanned < scanLimit && _hasMoreComments) {
      final snapshot = await _firestoreService.getKawanssCommentsBatch(
        startDate: _commentStartDate,
        endDate: _commentEndDate,
        limit: batchSize,
        startAfterDoc: _lastCommentDoc,
      );

      if (snapshot.docs.isEmpty) {
        _hasMoreComments = false;
        break;
      }

      _lastCommentDoc = snapshot.docs.last;
      scanned += snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final item = KawanssCommentModel.fromFirestore(doc, null);
        bool isMatch = false;
        
        final query = _commentSearchQuery.toLowerCase();
        if (_commentSearchField == 'Komentar' && item.comment.toLowerCase().contains(query)) isMatch = true;
        if (_commentSearchField == 'User' && item.username.toLowerCase().contains(query)) isMatch = true;

        if (isMatch) newItems.add(item);
      }
    }

    if (isContinuing) _comments.addAll(newItems); else _comments = newItems;
    
    _showContinueCommentSearch = (scanned >= scanLimit && _comments.length < targetResults && _hasMoreComments);
  }

  void continueCommentSearch() {
    searchComments(
      searchField: _commentSearchField,
      searchQuery: _commentSearchQuery,
      startDate: _commentStartDate,
      endDate: _commentEndDate,
      isContinuing: true,
    );
  }

  void resetCommentSearch() {
    loadInitialComments();
  }

  Future<bool> toggleCommentStatus(String commentId, bool currentStatus) async {
    try {
      bool newStatus = !currentStatus; // true(deleted) -> false(active)
      await _firestoreService.softDeleteKawanssComment(commentId, newStatus);
      
      // Update local state (Optimistic)
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(deleted: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }



  void _setState(KawanssPostViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
     _livePostSubscription?.cancel(); 
    _liveCommentSubscription?.cancel();
    super.dispose();
  }
}