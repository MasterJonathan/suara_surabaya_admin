// lib/core/services/call_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agora_token_service/agora_token_service.dart';

class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'calls';

  // STREAM BARU: Mengambil panggilan yang sedang dalam antrian
  Stream<QuerySnapshot> getQueuedCallsStream() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'queued') // Status baru untuk antrian
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // STREAM BARU: Mengambil panggilan yang sedang aktif
  Stream<QuerySnapshot> getActiveCallsStream() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'accepted')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentReference> createCallDocument({
    required String userId,
    required String username,
    required String photoURL,
    required bool isVideoCall,
    required int callerUid,
  }) {
    return _db.collection(_collection).add({
      'userId': userId,
      'username': username,
      'photoURL': photoURL,
      'isVideoCall': isVideoCall,
      'callerUid': callerUid, // Simpan UID Agora user
      'status': 'queued', // Status awal adalah 'queued'
      'createdAt': FieldValue.serverTimestamp(),
      'endedAt': FieldValue.serverTimestamp(),
      'channelName': '',
      'adminId': null, // Admin ID null saat di antrian
    });
  }

  Future<void> updateCallDocument(String callId, Map<String, dynamic> data) {
    return _db.collection(_collection).doc(callId).update(data);
  }

  Future<void> updateUserCallableStatus(String userId, bool status) {
    return _db.collection('users').doc(userId).update({'callable': status});
  }

  String generateToken(String channelName, int uid) {
    final appId = dotenv.env['AGORA_APP_ID']!;
    final appCertificate = dotenv.env['AGORA_APP_CERTIFICATE']!;
    final token = RtcTokenBuilder.build(
      appId: appId.trim(),
      appCertificate: appCertificate.trim(),
      channelName: channelName,
      uid: uid.toString(),
      role: RtcRole.publisher,
      expireTimestamp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
    );
    return token;
  }
}