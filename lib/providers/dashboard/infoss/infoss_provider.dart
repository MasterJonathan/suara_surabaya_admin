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
  
  // Subscription untuk Realtime Updates (Default Mode)
  StreamSubscription? _streamSubscription;
  StreamSubscription? _commentsSubscription;

  // State Data Utama
  List<InfossModel> _infossList = [];
  List<InfossCommentModel> _comments = []; 
  
  // State untuk Search / Pagination (Batch Mode)
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isSearching = false; 

  InfossViewState _state = InfossViewState.Busy;
  String? _errorMessage;

  // Getters
  List<InfossModel> get infossList => _infossList;
  List<InfossCommentModel> get comments => _comments;
  InfossViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;

  InfossProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    // Secara default, load data realtime
    _listenToInfoss();
    _listenToComments();
  }

  // ===========================================================================
  // BAGIAN 1: DEFAULT VIEW (REALTIME STREAM)
  // ===========================================================================

  void _listenToInfoss() {
    _isSearching = false; // Tandai sedang tidak search
    _streamSubscription?.cancel(); // Batalkan stream sebelumnya jika ada
    
    _streamSubscription = _firestoreService.getInfossStream().listen((data) {
      _infossList = data;
      _setState(InfossViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data Infoss: $error";
      _setState(InfossViewState.Idle);
    });
  }

  // ===========================================================================
  // BAGIAN 2: SEARCH MODE (SMART BATCH SCANNING)
  // ===========================================================================

  Future<void> searchInfoss({
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isLoadMore = false,
  }) async {
    // Jika query kosong, kembali ke mode realtime default
    if (searchQuery.isEmpty) {
      _listenToInfoss();
      return;
    }

    // Matikan stream realtime saat searching agar tidak bentrok
    _streamSubscription?.cancel();
    _isSearching = true;

    if (isLoadMore) {
      if (!_hasMoreData) return;
      _setState(InfossViewState.LoadingMore);
    } else {
      _setState(InfossViewState.Busy);
      _infossList = []; // Reset list untuk hasil pencarian baru
      _lastDocument = null;
      _hasMoreData = true;
    }

    _errorMessage = null;

    // Konfigurasi Scanning
    const int targetResults = 10; 
    const int maxScanLimit = 1000; 
    const int batchSize = 50; 

    int currentScanCount = 0;
    int newMatchesFound = 0;
    List<InfossModel> newItems = [];

    try {
      while (newMatchesFound < targetResults && currentScanCount < maxScanLimit) {
        // Panggil fungsi BATCH yang sudah Anda buat di FirestoreService
        final snapshot = await _firestoreService.getInfossBatch(
          startDate: startDate,
          endDate: endDate,
          limit: batchSize,
          startAfterDoc: _lastDocument,
        );

        if (snapshot.docs.isEmpty) {
          _hasMoreData = false;
          break;
        }

        _lastDocument = snapshot.docs.last;
        currentScanCount += snapshot.docs.length;

        // Filter di Memory
        for (var doc in snapshot.docs) {
          final infoss = InfossModel.fromFirestore(doc, null);
          
          if (infoss.judul.toLowerCase().contains(searchQuery.toLowerCase())) {
            newItems.add(infoss);
            newMatchesFound++;
            if (newMatchesFound >= targetResults) break;
          }
        }
      }

      if (isLoadMore) {
        _infossList.addAll(newItems);
      } else {
        _infossList = newItems;
      }

    } catch (e) {
      _errorMessage = "Gagal mencari data: $e";
    }

    _setState(InfossViewState.Idle);
  }

  // ===========================================================================
  // BAGIAN 3: CRUD (CREATE, UPDATE, DELETE)
  // ===========================================================================

  Future<bool> addInfoss(InfossModel infoss) async {
    _setState(InfossViewState.Busy);
    try {
      await _firestoreService.addInfoss(infoss);
      // Jika sedang mode search, mungkin perlu refresh manual atau biarkan user clear search
      if (!_isSearching) _setState(InfossViewState.Idle); 
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
      final imageUrl = await _firestoreService.uploadImageToStorage('infoss_images', imageBytes, fileName);
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

  void _listenToComments() {
    _commentsSubscription = _firestoreService.getInfossCommentsStream().listen((data) {
      _comments = data;
      notifyListeners(); 
    }, onError: (error) {
      print("Error listening to Infoss comments: $error");
    });
  }

  Future<bool> toggleCommentStatus(String commentId, bool currentStatus) async {
    try {
      await _firestoreService.softDeleteInfossComment(commentId, !currentStatus);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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

  Stream<List<InfossReplyModel>> fetchRepliesForComment(String infossId, String commentId) {
    try {
      return _firestoreService.getRepliesStreamForComment(infossId, commentId);
    } catch (e) {
      print("Error fetching replies: $e");
      return Stream.value([]);
    }
  }

  // ===========================================================================
  // HELPER
  // ===========================================================================

  void _setState(InfossViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}