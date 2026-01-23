// lib/providers/kontributor_profile_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_activity/activity_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_activity/call_history_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- TAMBAHKAN IMPORT INI

class KontributorProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _kontributorId;

  StreamSubscription? _postsSubscription;
  StreamSubscription? _callHistorySubscription;

  UserModel? _userProfile;
  List<KawanssModel> _posts = [];
  List<ActivityModel> _activities = [];
  List<CallHistoryModel> _callHistory = [];
  bool _isLoading = true;

  UserModel? get userProfile => _userProfile;
  List<KawanssModel> get posts => _posts;
  List<ActivityModel> get activities => _activities;
  List<CallHistoryModel> get callHistory => _callHistory;
  bool get isLoading => _isLoading;

  KontributorProfileProvider({
    required FirestoreService firestoreService,
    required String kontributorId,
  }) : _firestoreService = firestoreService, _kontributorId = kontributorId {
    fetchContributorData();
  }

  Future<void> fetchContributorData() async {
    _isLoading = true;
    notifyListeners();

    _userProfile = await _firestoreService.getUser(_kontributorId);

    if (_userProfile != null) {
      // --- PERBAIKAN DI SINI ---
      // Ambil data aktivitas dari field di dalam userProfile
      _activities = _userProfile!.aktivitas?.map((activityData) {
        // Lakukan pengecekan tipe yang aman
        final timestampValue = activityData['waktu'];
        DateTime timestamp;
        if (timestampValue is Timestamp) {
          timestamp = timestampValue.toDate();
        } else {
          // Fallback jika tipe datanya salah
          timestamp = DateTime.now();
        }

        return ActivityModel(
          id: timestamp.toIso8601String(), // ID unik dari timestamp
          description: activityData['namaAktivitas'] ?? '',
          timestamp: timestamp,
          type: ActivityType.unknown, // Tipe bisa ditentukan lebih lanjut jika perlu
        );
      }).toList() ?? [];
      _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // -------------------------

      _postsSubscription?.cancel();
      _postsSubscription = _firestoreService.getPostsByUser(_kontributorId).listen((data) {
        _posts = data;
        if(hasListeners) notifyListeners();
      });

      _callHistorySubscription?.cancel();
      _callHistorySubscription = _firestoreService.getCallHistoryByUser(_kontributorId).listen((data) {
        _callHistory = data;
        if(hasListeners) notifyListeners();
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _callHistorySubscription?.cancel();
    super.dispose();
  }
}