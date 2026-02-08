// lib/models/call_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String id; // Document ID
  final String adminId;
  final String channelName;
  final DateTime createdAt;
  final bool isVideoCall;
  final String photoURL;
  final String status;
  final String token;
  final String userId;
  final String username;

  CallModel({
    required this.id,
    required this.adminId,
    required this.channelName,
    required this.createdAt,
    required this.isVideoCall,
    required this.photoURL,
    required this.status,
    required this.token,
    required this.userId,
    required this.username,
  });

  factory CallModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return CallModel(
      id: snapshot.id,
      adminId: data['adminId'] ?? '',
      channelName: data['channelName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVideoCall: data['isVideoCall'] ?? false,
      photoURL: data['photoURL'] ?? '',
      status: data['status'] ?? 'ended',
      token: data['token'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
    );
  }

  // toFirestore tidak diperlukan di model ini karena kita membuat
  // dokumen langsung di service layer, tapi bisa ditambahkan jika perlu.
}