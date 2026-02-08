// lib/providers/dashboard/call_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:suara_surabaya_admin/core/services/call_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CallProvider extends ChangeNotifier {
  final CallService _callService;
  final String _currentUserId;

  StreamSubscription? _queuedCallsSubscription;
  StreamSubscription? _activeCallsSubscription;

  List<QueryDocumentSnapshot> _queuedCalls = [];
  List<QueryDocumentSnapshot> _activeCalls = [];
  List<QueryDocumentSnapshot> get queuedCalls => _queuedCalls;
  List<QueryDocumentSnapshot> get activeCalls => _activeCalls;

  CallProvider({
    required CallService callService,
    required String currentUserId,
  }) : _callService = callService,
       _currentUserId = currentUserId {
    // --- PERBAIKAN: Atur state awal menjadi kosong untuk mencegah ghost list dari cache ---
    _queuedCalls = [];
    _activeCalls = [];
    // ------------------------------------------------------------------------------------
    _listenToQueuedCalls();
    _listenToActiveCalls();
  }

  void _listenToQueuedCalls() {
    _queuedCallsSubscription = _callService.getQueuedCallsStream().listen((
      snapshot,
    ) {
      _queuedCalls = snapshot.docs;

      // --- LOGIKA BARU: Cek & Bersihkan Panggilan Hantu ---
      _cleanupGhostCalls();
      // ----------------------------------------------------

      if (hasListeners) notifyListeners();
    });
  }

  void _cleanupGhostCalls() {
    final now = DateTime.now();

    // Loop semua panggilan yang sedang antri
    for (var doc in _queuedCalls) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final createdAtRaw = data['createdAt'];

        if (createdAtRaw != null && createdAtRaw is Timestamp) {
          final createdAt = createdAtRaw.toDate();
          final difference = now.difference(createdAt);

          // Batas Waktu: 2 Menit (120 Detik)
          if (difference.inSeconds > 120) {
            print(
              "🧹 Auto-Rejecting Ghost Call: ${doc.id} (Age: ${difference.inSeconds}s)",
            );

            // Set status ke 'timeout' agar terbedakan dengan reject manual
            // Ini akan memicu stream update, dan panggilan akan hilang dari list UI
            _callService.updateCallDocument(doc.id, {'status': 'timeout'});
          }
        }
      } catch (e) {
        print("Error checking call timeout: $e");
      }
    }
  }

  void _listenToActiveCalls() {
    _activeCallsSubscription = _callService.getActiveCallsStream().listen((
      snapshot,
    ) {
      _activeCalls = snapshot.docs;

      // --- LOGIKA BARU: Cek Admin Ghosting (Sudah Jawab tapi tidak Gabung) ---
      _cleanupAbandonedCalls();
      // ----------------------------------------------------------------------

      if (hasListeners) notifyListeners();
    });
  }

  void _cleanupAbandonedCalls() {
    final now = DateTime.now();
    for (var doc in _activeCalls) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        final adminJoined = data['adminJoined'] ?? false; // Default false
        final acceptedAtRaw = data['acceptedAt'];

        // Jika status accepted TAPI admin belum masuk room > 1 Menit
        if (status == 'accepted' &&
            !adminJoined &&
            acceptedAtRaw is Timestamp) {
          final acceptedAt = acceptedAtRaw.toDate();
          final difference = now.difference(acceptedAt);

          if (difference.inSeconds > 60) {
            print(
              "🧹 Auto-Cancel Abandoned Call: ${doc.id} (Admin lupa gabung > 60s)",
            );
            // Ubah status jadi 'cancelled' atau 'timeout' agar user di HP berhenti menunggu
            _callService.updateCallDocument(doc.id, {'status': 'timeout'});
          }
        }
      } catch (e) {
        print("Error checking abandoned calls: $e");
      }
    }
  }

  Future<String?> initiateCall({
    required UserModel currentUser,
    required bool isVideoCall,
  }) async {
    try {
      final int callerUid = Random().nextInt(999999) + 1;
      final callDocRef = await _callService.createCallDocument(
        userId: currentUser.id,
        username: currentUser.nama,
        photoURL: currentUser.photoURL ?? '',
        isVideoCall: isVideoCall,
        callerUid: callerUid,
      );
      await _callService.updateCallDocument(callDocRef.id, {
        'channelName': callDocRef.id,
      });
      return callDocRef.id;
    } catch (e) {
      print("Error initiating call: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> answerAndClaimCall(
    DocumentSnapshot callDoc,
    String adminName, // <--- Parameter Baru
  ) async {
    try {
      final String callId = callDoc.id;
      final String channelName =
          (callDoc.data() as Map<String, dynamic>)['channelName'];
      final int callerUid =
          (callDoc.data() as Map<String, dynamic>)['callerUid'];

      final int adminUid = Random().nextInt(999999) + 1;
      final String adminToken = _callService.generateToken(
        channelName,
        adminUid,
      );
      final String callerToken = _callService.generateToken(
        channelName,
        callerUid,
      );

      await _callService.updateCallDocument(callId, {
        'status': 'accepted',
        'adminId': _currentUserId,
        'adminName': adminName,
        'callerToken': callerToken,
        // --- DATA BARU ---
        'acceptedAt': FieldValue.serverTimestamp(), // Waktu admin klik jawab
        'adminJoined': false, // Flag admin belum masuk room
        // -----------------
      });

      return {
        'channelName': channelName,
        'token': adminToken,
        'uid': adminUid,
        'originalUserId': (callDoc.data() as Map<String, dynamic>)['userId'],
        'originalCallerUid': callerUid,
      };
    } catch (e) {
      print("Gagal menjawab panggilan: $e");
      return null;
    }
  }

  Future<void> setAdminJoined(String callId) async {
    await _callService.updateCallDocument(callId, {'adminJoined': true});
  }

  Map<String, dynamic> joinExistingCall(DocumentSnapshot callDoc) {
    final callData = callDoc.data() as Map<String, dynamic>;
    final String channelName = callData['channelName'];
    final int joiningAdminUid = Random().nextInt(999999) + 1;
    final String joiningAdminToken = _callService.generateToken(
      channelName,
      joiningAdminUid,
    );

    return {
      'channelName': channelName,
      'token': joiningAdminToken,
      'uid': joiningAdminUid,
      'originalUserId': callData['userId'],
      'originalCallerUid': callData['callerUid'],
    };
  }

  Future<void> rejectCall(String callId) async {
    await _callService.updateCallDocument(callId, {'status': 'rejected'});
  }

  Future<void> cancelCall(String callId) async {
    await _callService.updateCallDocument(callId, {'status': 'cancelled'});
  }

  Future<void> endCall(String callId) async {
    await _callService.updateCallDocument(callId, {
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _queuedCallsSubscription?.cancel();
    _activeCallsSubscription?.cancel();
    super.dispose();
  }
}
