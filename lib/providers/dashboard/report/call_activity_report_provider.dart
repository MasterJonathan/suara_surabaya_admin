import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/report/call_activity_report_model.dart';

enum ReportViewState { Idle, Busy }

class CallActivityReportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  ReportViewState _state = ReportViewState.Idle;
  String? _errorMessage;
  
  List<CallHourlyReport> _reportData = [];
  int _totalCalls = 0;
  int _totalVoice = 0;
  int _totalVideo = 0;
  String _busiestHour = "-";

  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<CallHourlyReport> get reportData => _reportData;
  int get totalCalls => _totalCalls;
  int get totalVoice => _totalVoice;
  int get totalVideo => _totalVideo;
  String get busiestHour => _busiestHour;

  CallActivityReportProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> generateReport(DateTime startDate, DateTime endDate) async {
    _state = ReportViewState.Busy;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ambil SEMUA data dalam rentang tanggal (gunakan method batch existing)
      // Kita set limit tinggi (misal 10.000) karena ini report, bukan pagination UI
      final snapshot = await _firestoreService.getCallHistoryBatch(
        startDate: startDate,
        endDate: endDate.add(const Duration(days: 1)), // Inklusif sampai akhir hari
        limit: 10000, 
        startAfterDoc: null,
      );

      // 2. Inisialisasi Struktur Data
      // Map<TanggalString, CallHourlyReport>
      Map<String, Map<int, int>> tempHourlyData = {};
      Map<String, int> tempVoiceData = {};
      Map<String, int> tempVideoData = {};
      Map<int, int> globalHourCounts = {}; // Untuk hitung jam tersibuk

      // Generate keys untuk semua tanggal dalam range (biar tabel tidak bolong)
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        tempHourlyData[key] = {for (var i = 0; i < 24; i++) i: 0};
        tempVoiceData[key] = 0;
        tempVideoData[key] = 0;
      }

      _totalCalls = 0;
      _totalVoice = 0;
      _totalVideo = 0;

      // 3. Proses Aggregasi
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['createdAt'] as Timestamp).toDate();
        final isVideo = data['isVideoCall'] == true;
        
        final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
        final hour = timestamp.hour;

        if (tempHourlyData.containsKey(dateKey)) {
          tempHourlyData[dateKey]![hour] = (tempHourlyData[dateKey]![hour] ?? 0) + 1;
          
          if (isVideo) {
            tempVideoData[dateKey] = (tempVideoData[dateKey] ?? 0) + 1;
            _totalVideo++;
          } else {
            tempVoiceData[dateKey] = (tempVoiceData[dateKey] ?? 0) + 1;
            _totalVoice++;
          }

          globalHourCounts[hour] = (globalHourCounts[hour] ?? 0) + 1;
          _totalCalls++;
        }
      }

      // 4. Finalisasi Data List
      _reportData = tempHourlyData.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        return CallHourlyReport(
          date: date,
          hourlyCounts: entry.value,
          totalVoiceCalls: tempVoiceData[entry.key] ?? 0,
          totalVideoCalls: tempVideoData[entry.key] ?? 0,
        );
      }).toList();

      // Sort tanggal descending (terbaru diatas)
      _reportData.sort((a, b) => b.date.compareTo(a.date));

      // 5. Hitung Statistik Tambahan
      if (globalHourCounts.isNotEmpty) {
        // Cari jam dengan value tertinggi
        var busiestEntry = globalHourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        _busiestHour = "${busiestEntry.key.toString().padLeft(2, '0')}:00 (${busiestEntry.value})";
      } else {
        _busiestHour = "-";
      }

    } catch (e) {
      _errorMessage = "Gagal membuat laporan: $e";
    }

    _state = ReportViewState.Idle;
    notifyListeners();
  }

  // Generate CSV String (Untuk Export)
  String generateCsvData() {
    String csv = "Tanggal,Total,Voice,Video,00:00,01:00,02:00,03:00,04:00,05:00,06:00,07:00,08:00,09:00,10:00,11:00,12:00,13:00,14:00,15:00,16:00,17:00,18:00,19:00,20:00,21:00,22:00,23:00\n";
    
    for (var report in _reportData) {
      String row = "${DateFormat('yyyy-MM-dd').format(report.date)},${report.dailyTotal},${report.totalVoiceCalls},${report.totalVideoCalls}";
      for (int i = 0; i < 24; i++) {
        row += ",${report.hourlyCounts[i]}";
      }
      csv += "$row\n";
    }
    return csv;
  }
}