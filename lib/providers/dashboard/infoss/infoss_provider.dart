// lib/providers/dashboard/infoss/infoss_provider.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_reply_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum InfossViewState { Idle, Busy, LoadingMore }

class InfossProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  StreamSubscription? _streamSubscription;
  StreamSubscription? _commentsSubscription;
  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription? _liveCommentSubscription;

  List<InfossModel> _infossList = [];
  List<InfossCommentModel> _comments = [];

  bool _isCommentLiveMode = false;

  // --- STATE BARU UNTUK SEARCH & PAGINATION ---
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isUsingFilter = false;
  String _searchField = 'Judul'; // Default search field
  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _totalDocsScanned = 0;
  bool _showContinueSearchButton = false;
  // ---------------------------------------------

  InfossViewState _state = InfossViewState.Busy;
  String? _errorMessage;

  List<InfossModel> get infossList => _infossList;
  List<InfossCommentModel> get comments => _comments;
  InfossViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get showContinueSearchButton => _showContinueSearchButton;

  // --- For Comment

  // --- STATE KHUSUS KOMENTAR ---

  DocumentSnapshot? _lastCommentDoc;
  bool _hasMoreComments = true;
  bool _isSearchingComments = false;
  bool _isUsingCommentFilter = false;

  String _commentSearchField = 'Komentar';
  String _commentSearchQuery = '';
  DateTime _commentStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _commentEndDate = DateTime.now();

  bool _showContinueCommentSearch = false;

  // Getter Komentar Updated
  bool get hasMoreComments => _hasMoreComments;
  bool get showContinueCommentSearch => _showContinueCommentSearch;
  bool get isCommentLiveMode => _isCommentLiveMode; // Getter Mode Live

  InfossProvider({required FirestoreService firestoreService})
    : _firestoreService = firestoreService {
    loadInitialData();
  }

  void resetSearch() {
    loadInitialData(); // Kembali ke load awal
  }

  void loadInitialData() {
    _searchQuery = '';
    _searchField = 'Judul';
    _showContinueSearchButton = false;
    _errorMessage = null;
    _isUsingFilter = false; // Tandai kita TIDAK pakai filter tanggal

    // Default tanggal hanya untuk UI DatePicker jika user mau filter nanti
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    // Reset dan Load
    _infossList = [];
    _lastDocument = null;
    _hasMoreData = true; // Pastikan ini TRUE di awal

    // Panggil langsung fungsi fetch batch
    _fetchNormalBatch(false);
  }

  // --- FUNGSI BARU: Lanjutkan Pencarian (untuk tombol 'Load More') ---
  Future<void> continueSearch() async {
    await searchInfoss(
      searchField: _searchField,
      searchQuery: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      isContinuing: true,
    );
  }

  // --- REVISI UTAMA: Logika Pencarian Cerdas ---
  Future<void> searchInfoss({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    _isSearching = searchQuery.isNotEmpty;

    if (isContinuing) {
      if (!_hasMoreData) return;
      _setState(InfossViewState.LoadingMore);
    } else {
      _setState(InfossViewState.Busy);
      _infossList = [];
      _lastDocument = null;
      _hasMoreData = true;
      _showContinueSearchButton = false;

      // Simpan state
      _searchField = searchField;
      _searchQuery = searchQuery;
      _startDate = startDate;
      _endDate = endDate;

      // Cek apakah user benar-benar melakukan filter (Query isi ATAU Tanggal berubah)
      // Jika Query kosong, kita anggap user ingin pakai filter tanggal
      _isUsingFilter = true;
    }

    try {
      if (searchQuery.trim().isEmpty) {
        // Load Batch Normal (Bisa dengan filter tanggal atau semua data)
        await _fetchNormalBatch(isContinuing);
      } else if (searchField == 'Kategori') {
        await _fetchCategoryByBatch(isContinuing);
      } else {
        await _scanTitleByBatch(isContinuing);
      }
    } catch (e) {
      _errorMessage = "Gagal memuat data: $e";
    }

    _setState(InfossViewState.Idle);
  }

  Future<void> _fetchNormalBatch(bool isContinuing) async {
    const int limit = 10;

    QuerySnapshot<Map<String, dynamic>> snapshot;

    // LOGIKA PENTING:
    // Jika _isUsingFilter = false (Initial Load), pakai getAllInfossBatch (tanpa tanggal)
    // Jika _isUsingFilter = true (User pilih tanggal), pakai getInfossBatch (dengan tanggal)
    if (!_isUsingFilter) {
      snapshot = await _firestoreService.getAllInfossBatch(
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    } else {
      snapshot = await _firestoreService.getInfossBatch(
        startDate: _startDate,
        endDate: _endDate,
        limit: limit,
        startAfterDoc: _lastDocument,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
      if (!isContinuing)
        _setState(
          InfossViewState.Idle,
        ); // Stop loading jika data kosong di awal
      return;
    }

    if (snapshot.docs.length < limit) {
      _hasMoreData = false;
    }

    _lastDocument = snapshot.docs.last;
    final newItems =
        snapshot.docs
            .map((doc) => InfossModel.fromFirestore(doc, null))
            .toList();

    if (isContinuing) {
      _infossList.addAll(newItems);
    } else {
      _infossList = newItems;
    }

    // Force notify agar UI update
    notifyListeners();
  }

  Future<void> _fetchCategoryByBatch(bool isLoadMore) async {
    if (!isLoadMore) {
      _infossList = [];
      _lastDocument = null;
      _hasMoreData = true;
    }
    if (!_hasMoreData) return;

    final snapshot = await _firestoreService.getInfossBatchByCategory(
      category: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      limit: 10, // Kategori bisa langsung limit 10
      startAfterDoc: _lastDocument,
    );

    if (snapshot.docs.isEmpty) {
      _hasMoreData = false;
      return;
    }

    _lastDocument = snapshot.docs.last;
    final newItems =
        snapshot.docs
            .map((doc) => InfossModel.fromFirestore(doc, null))
            .toList();
    _infossList.addAll(newItems);
  }

  Future<void> _scanTitleByBatch(bool isContinuing) async {
    const int targetResults = 10;
    const int scanLimitPerCycle = 200;
    const int batchSize = 50;

    int docsScannedInThisCycle = 0;
    List<InfossModel> newItems = [];

    if (!isContinuing) {
      _infossList = [];
      _lastDocument = null;
      _hasMoreData = true;
      _totalDocsScanned = 0;
    }

    while (_infossList.length < targetResults &&
        docsScannedInThisCycle < scanLimitPerCycle &&
        _hasMoreData) {
      final snapshot = await _firestoreService.getInfossBatch(
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
      _totalDocsScanned += snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final infoss = InfossModel.fromFirestore(doc, null);
        if (infoss.judul.toLowerCase().contains(_searchQuery.toLowerCase())) {
          newItems.add(infoss);
        }
      }
    }

    _infossList.addAll(newItems);

    // Tentukan apakah tombol "Lanjutkan Pencarian" perlu ditampilkan
    if (docsScannedInThisCycle >= scanLimitPerCycle &&
        _infossList.length < targetResults &&
        _hasMoreData) {
      _showContinueSearchButton = true;
    } else {
      _showContinueSearchButton = false;
    }
  }

  // ===========================================================================
  // BAGIAN 3: CRUD (CREATE, UPDATE, DELETE)
  // ===========================================================================

  Future<bool> addInfoss(InfossModel infoss) async {
    _setState(InfossViewState.Busy);
    try {
      // Gunakan method baru yang mengembalikan ID
      final newId = await _firestoreService.addInfossWithIdReturn(infoss);

      // Update model lokal dengan ID baru
      final newModel = infoss.copyWith(id: newId);

      // Masukkan ke paling atas list secara manual
      _infossList.insert(0, newModel);

      _setState(InfossViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = "Gagal menambah data: $e";
      _setState(InfossViewState.Idle);
      return false;
    }
  }

  Future<bool> updateInfoss(InfossModel infoss) async {
    _setState(InfossViewState.Busy);
    try {
      await _firestoreService.updateInfoss(infoss);

      // Jika sedang mode search, update item di list lokal agar UI berubah
      if (_isSearching) {
        final index = _infossList.indexWhere((item) => item.id == infoss.id);
        if (index != -1) {
          _infossList[index] = infoss;
        }
      }

      _setState(InfossViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(InfossViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteInfoss(String infossId) async {
    _setState(InfossViewState.Busy);
    try {
      await _firestoreService.deleteInfoss(infossId);

      // Hapus dari list lokal juga
      _infossList.removeWhere((item) => item.id == infossId);

      _setState(InfossViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(InfossViewState.Idle);
      return false;
    }
  }

  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final imageUrl = await _firestoreService.uploadImageToStorage(
        'infoss_images',
        imageBytes,
        fileName,
      );
      return imageUrl;
    } catch (e) {
      _errorMessage = "Gagal meng-upload gambar: $e";
      _setState(InfossViewState.Idle);
      rethrow;
    }
  }

  // ===========================================================================
  // BAGIAN 4: MANAJEMEN KOMENTAR
  // ===========================================================================

  // --- 1. TOGGLE LIVE MODE ---
  void toggleCommentLiveMode(bool value) {
    _isCommentLiveMode = value;
    if (_isCommentLiveMode) {
      _startCommentLiveMonitoring();
    } else {
      _stopCommentLiveMonitoring();
      loadInitialComments(); // Balik ke manual pagination
    }
    notifyListeners();
  }

  void _startCommentLiveMonitoring() {
    _state = InfossViewState.Busy;
    _comments = [];
    notifyListeners();

    // Matikan stream lama jika ada
    _liveCommentSubscription?.cancel();

    // Matikan juga stream comment detail jika sedang aktif (opsional)
    _commentsSubscription?.cancel();

    // Start Live Stream
    _liveCommentSubscription = _firestoreService
        .getInfossCommentsLiveStream(limit: 50)
        .listen(
          (data) {
            _comments = data;
            _state = InfossViewState.Idle;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = "Live comment stream error: $error";
            _state = InfossViewState.Idle;
            notifyListeners();
          },
        );
  }

  void _stopCommentLiveMonitoring() {
    _liveCommentSubscription?.cancel();
    _liveCommentSubscription = null;
  }

  // --- 2. LOAD INITIAL COMMENTS (MANUAL) ---
  void loadInitialComments() {
    if (_isCommentLiveMode) return; // Jangan load manual jika sedang live

    _commentSearchQuery = '';
    _commentSearchField = 'Komentar';
    _showContinueCommentSearch = false;
    _isUsingCommentFilter = false;

    _commentStartDate = DateTime.now().subtract(const Duration(days: 30));
    _commentEndDate = DateTime.now();

    _comments = [];
    _lastCommentDoc = null;
    _hasMoreComments = true;

    _fetchNormalCommentBatch(false);
  }

  // --- 3. SEARCH & PAGINATION COMMENTS ---
  Future<void> searchComments({
    required String searchField,
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    if (_isCommentLiveMode) return; // Search disabled di Live Mode

    // Pastikan live stream mati
    _commentsSubscription?.cancel();

    if (isContinuing) {
      if (!_hasMoreComments) return;
      _setState(InfossViewState.LoadingMore);
    } else {
      _setState(InfossViewState.Busy);
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
      print("❌ [InfossProvider] Comment Error: $e");
      _errorMessage = "Gagal memuat komentar.";
    }
    _setState(InfossViewState.Idle);
  }

  Future<void> _fetchNormalCommentBatch(bool isContinuing) async {
    const int limit = 20;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (!_isUsingCommentFilter) {
      snapshot = await _firestoreService.getAllInfossCommentsBatch(
        limit: limit,
        startAfterDoc: _lastCommentDoc,
      );
    } else {
      snapshot = await _firestoreService.getInfossCommentsBatch(
        startDate: _commentStartDate,
        endDate: _commentEndDate,
        limit: limit,
        startAfterDoc: _lastCommentDoc,
      );
    }

    if (snapshot.docs.isEmpty) {
      _hasMoreComments = false;
      if (!isContinuing) _setState(InfossViewState.Idle);
      return;
    }

    if (snapshot.docs.length < limit) _hasMoreComments = false;

    _lastCommentDoc = snapshot.docs.last;
    final newItems =
        snapshot.docs
            .map((doc) => InfossCommentModel.fromFirestore(doc, null))
            .toList();

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
    List<InfossCommentModel> newItems = [];

    while (_comments.length < targetResults &&
        scanned < scanLimit &&
        _hasMoreComments) {
      final snapshot = await _firestoreService.getInfossCommentsBatch(
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
        final item = InfossCommentModel.fromFirestore(doc, null);
        bool isMatch = false;

        final query = _commentSearchQuery.toLowerCase();
        if (_commentSearchField == 'Komentar' &&
            item.comment.toLowerCase().contains(query))
          isMatch = true;
        if (_commentSearchField == 'User' &&
            item.username.toLowerCase().contains(query))
          isMatch = true;

        if (isMatch) newItems.add(item);
      }
    }

    if (isContinuing)
      _comments.addAll(newItems);
    else
      _comments = newItems;

    _showContinueCommentSearch =
        (scanned >= scanLimit &&
            _comments.length < targetResults &&
            _hasMoreComments);
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

  // Override toggle status agar update list lokal
  Future<bool> toggleCommentStatus(String commentId, bool currentStatus) async {
    try {
      bool newStatus = !currentStatus;
      await _firestoreService.softDeleteInfossComment(commentId, newStatus);

      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(deleted: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Stream<List<InfossCommentModel>> fetchCommentsForInfoss(String infossId) {
    try {
      return _firestoreService.getCommentsStreamForInfoss(infossId);
    } catch (e) {
      print("Error fetching comments: $e");
      return Stream.value([]);
    }
  }

  Stream<List<InfossReplyModel>> fetchRepliesForComment(
    String infossId,
    String commentId,
  ) {
    try {
      return _firestoreService.getRepliesStreamForComment(infossId, commentId);
    } catch (e) {
      print("Error fetching replies: $e");
      return Stream.value([]);
    }
  }

  // Helper
  void _setState(InfossViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveCommentSubscription?.cancel(); // Cancel Live Stream
    _commentsSubscription?.cancel();
    super.dispose();
  }
}
