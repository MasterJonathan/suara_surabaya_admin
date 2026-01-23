// lib/providers/dashboard/report/kawanss_post_report_provider.dart

import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyKawanssReport {
  final DateTime date;
  final int count;
  DailyKawanssReport({required this.date, required this.count});
}

enum ReportViewState { Idle, Busy }

class KawanssPostReportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<DailyKawanssReport> _reportData = [];
  List<KawanssModel> _topPosts = []; // Top 10 post berdasarkan like
  
  ReportViewState _state = ReportViewState.Idle;
  String? _errorMessage;

  // Statistik Agregat
  int _totalLikes = 0;
  int _totalComments = 0;

  // Getters
  List<DailyKawanssReport> get reportData => _reportData;
  List<KawanssModel> get topPosts => _topPosts;
  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;

  int get totalPosts => _reportData.fold(0, (sum, item) => sum + item.count);
  int get totalLikes => _totalLikes;
  int get totalComments => _totalComments;
  
  double get averagePerDay {
    if (_reportData.isEmpty) return 0.0;
    return totalPosts / _reportData.length;
  }

  String get busiestDay {
    if (_reportData.isEmpty) return "-";
    var maxEntry = _reportData.reduce((a, b) => a.count > b.count ? a : b);
    return DateFormat('EEEE, dd MMM', 'id').format(maxEntry.date);
  }

  KawanssPostReportProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> generateReport(DateTime startDate, DateTime endDate) async {
    _setState(ReportViewState.Busy);
    _errorMessage = null;
    _reportData = [];
    _topPosts = [];
    _totalLikes = 0;
    _totalComments = 0;

    try {
      final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final posts = await _firestoreService.getKawanssInDateRange(startDate, adjustedEndDate);

      final Map<DateTime, int> dailyCounts = {};

      // Inisialisasi range tanggal
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
        dailyCounts[date] = 0;
      }

      for (final post in posts) {
        // Hitung total harian
        final dateOnly = DateTime(post.uploadDate.year, post.uploadDate.month, post.uploadDate.day);
        if (dailyCounts.containsKey(dateOnly)) {
          dailyCounts[dateOnly] = (dailyCounts[dateOnly] ?? 0) + 1;
        }

        // Hitung total engagement
        _totalLikes += post.jumlahLike;
        _totalComments += post.jumlahComment;
      }

      _reportData = dailyCounts.entries.map((entry) {
        return DailyKawanssReport(date: entry.key, count: entry.value);
      }).toList();
      
      _reportData.sort((a, b) => a.date.compareTo(b.date));

      // Siapkan Top 10 Posts
      _topPosts = List.from(posts);
      _topPosts.sort((a, b) => b.jumlahLike.compareTo(a.jumlahLike)); // Sort by Like Descending
      if (_topPosts.length > 10) {
        _topPosts = _topPosts.sublist(0, 10);
      }

    } catch (e) {
      _errorMessage = "Gagal membuat laporan: $e";
    }

    _setState(ReportViewState.Idle);
  }

  String generateCsvData() {
    List<String> rows = [];
    rows.add("Tanggal,Jumlah Postingan"); 

    for (var item in _reportData) {
      rows.add("${DateFormat('yyyy-MM-dd').format(item.date)},${item.count}");
    }
    return rows.join("\n");
  }
  
  void _setState(ReportViewState newState) {
    _state = newState;
    notifyListeners();
  }
}