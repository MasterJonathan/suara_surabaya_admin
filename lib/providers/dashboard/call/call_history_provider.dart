import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/call/call_history_log_model.dart';

enum CallHistoryViewState { Idle, Busy, LoadingMore }

class CallHistoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<CallHistoryLogModel> _calls = [];
  
  // State Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isUsingFilter = false;

  // Filter State
  String _searchQuery = ''; // Filter by Caller Name (Client Side Filtering for now)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7)); // Default 7 hari
  DateTime _endDate = DateTime.now();
  
  CallHistoryViewState _state = CallHistoryViewState.Busy;
  String? _errorMessage;

  List<CallHistoryLogModel> get calls => _calls;
  CallHistoryViewState get state => _state;
  bool get hasMoreData => _hasMoreData;

  CallHistoryProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // --- INITIAL LOAD ---
  void loadInitialData() {
    _searchQuery = '';
    _isUsingFilter = false;
    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();
    _resetPagination();
    _fetchBatch(false);
  }

  // --- SEARCH & FILTER ---
  Future<void> searchCalls({
    required String searchQuery,
    required DateTime startDate,
    required DateTime endDate,
    bool isContinuing = false,
  }) async {
    if (!isContinuing) {
      _resetPagination();
      _searchQuery = searchQuery;
      _startDate = startDate;
      _endDate = endDate;
      _isUsingFilter = true;
      _state = CallHistoryViewState.Busy;
    } else {
      if (!_hasMoreData) return;
      _state = CallHistoryViewState.LoadingMore;
    }
    notifyListeners();

    await _fetchBatch(isContinuing);
  }

  Future<void> _fetchBatch(bool isContinuing) async {
    try {
      const int limit = 20;
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (!_isUsingFilter) {
        snapshot = await _firestoreService.getAllCallHistoryBatch(
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      } else {
        snapshot = await _firestoreService.getCallHistoryBatch(
          startDate: _startDate,
          endDate: _endDate,
          limit: limit,
          startAfterDoc: _lastDocument,
        );
      }

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        _state = CallHistoryViewState.Idle;
        notifyListeners();
        return;
      }

      _hasMoreData = snapshot.docs.length >= limit;
      _lastDocument = snapshot.docs.last;

      final newItems = snapshot.docs
          .map((doc) => CallHistoryLogModel.fromFirestore(doc, null))
          .where((item) {
            // Client-side filtering untuk nama (karena Firestore limitasi query)
            if (_searchQuery.isEmpty) return true;
            return item.callerName.toLowerCase().contains(_searchQuery.toLowerCase());
          })
          .toList();

      if (isContinuing) {
        _calls.addAll(newItems);
      } else {
        _calls = newItems;
      }
    } catch (e) {
      _errorMessage = "Gagal memuat history: $e";
    }
    
    _state = CallHistoryViewState.Idle;
    notifyListeners();
  }

  void continueSearch() {
    searchCalls(
      searchQuery: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      isContinuing: true,
    );
  }

  void _resetPagination() {
    _calls = [];
    _lastDocument = null;
    _hasMoreData = true;
    _errorMessage = null;
  }
}