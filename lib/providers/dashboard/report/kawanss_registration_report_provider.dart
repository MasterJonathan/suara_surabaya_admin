// lib/providers/dashboard/report/kawanss_registration_report_provider.dart

import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/report/kawanss_registration_report_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReportViewState { Idle, Busy }

class KawanSSRegistrationReportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<HourlyRegistrationReport> _reportData = [];
  ReportViewState _state = ReportViewState.Idle;
  String? _errorMessage;

  List<HourlyRegistrationReport> get reportData => _reportData;
  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;

  // --- Statistik untuk Summary Cards ---
  int get totalRegistrations {
    return _reportData.fold(0, (sum, item) => sum + item.hourlyCounts.values.fold(0, (a, b) => a + b));
  }

  double get averagePerDay {
    if (_reportData.isEmpty) return 0.0;
    return totalRegistrations / _reportData.length;
  }

  String get busiestHour {
    if (_reportData.isEmpty) return "-";
    
    // Map untuk menyimpan total per jam di semua hari
    Map<int, int> totalPerHour = {};
    for (int i = 0; i < 24; i++) totalPerHour[i] = 0;

    for (var report in _reportData) {
      report.hourlyCounts.forEach((hour, count) {
        totalPerHour[hour] = (totalPerHour[hour] ?? 0) + count;
      });
    }

    // Cari jam dengan nilai tertinggi
    var maxEntry = totalPerHour.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (maxEntry.value == 0) return "-";
    return "${maxEntry.key.toString().padLeft(2, '0')}:00";
  }
  // -------------------------------------

  KawanSSRegistrationReportProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> generateReport(DateTime startDate, DateTime endDate) async {
    _setState(ReportViewState.Busy);
    _errorMessage = null;
    _reportData = [];

    try {
      // Pastikan endDate mencakup seluruh hari tersebut (sampai 23:59:59)
      final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final users = await _firestoreService.getUsersInDateRange(startDate, adjustedEndDate);

      final Map<DateTime, Map<int, int>> dailyAggregates = {};

      // Inisialisasi range tanggal agar hari yang kosong tetap muncul di tabel (nilai 0)
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
        dailyAggregates[date] = { for (var h = 0; h < 24; h++) h: 0 };
      }

      for (final user in users) {
        final dateOnly = DateTime(user.joinDate.year, user.joinDate.month, user.joinDate.day);
        final hour = user.joinDate.hour;

        if (dailyAggregates.containsKey(dateOnly)) {
           dailyAggregates[dateOnly]![hour] = (dailyAggregates[dateOnly]![hour] ?? 0) + 1;
        }
      }

      _reportData = dailyAggregates.entries.map((entry) {
        return HourlyRegistrationReport(date: entry.key, hourlyCounts: entry.value);
      }).toList();
      
      _reportData.sort((a, b) => a.date.compareTo(b.date));

    } catch (e) {
      _errorMessage = "Gagal membuat laporan: $e";
    }

    _setState(ReportViewState.Idle);
  }

  // --- Fitur Export CSV ---
  String generateCsvData() {
    List<String> rows = [];
    
    // Header
    List<String> header = ["Tanggal"];
    for (int i = 0; i < 24; i++) header.add("$i:00");
    header.add("Total Harian");
    rows.add(header.join(","));

    // Data Rows
    for (var item in _reportData) {
      List<String> row = [];
      row.add(DateFormat('yyyy-MM-dd').format(item.date));
      
      int dailyTotal = 0;
      for (int i = 0; i < 24; i++) {
        int count = item.hourlyCounts[i] ?? 0;
        dailyTotal += count;
        row.add(count.toString());
      }
      row.add(dailyTotal.toString());
      
      rows.add(row.join(","));
    }

    return rows.join("\n");
  }
  
  void _setState(ReportViewState newState) {
    _state = newState;
    notifyListeners();
  }
}