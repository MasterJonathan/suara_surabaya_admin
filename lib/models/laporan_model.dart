import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanModel {
  final String id; 
  final String postId; 
  final DateTime timestamp;
  final String userId; 

  LaporanModel({
    required this.id,
    required this.postId,
    required this.timestamp,
    required this.userId,
  });

  factory LaporanModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return LaporanModel(
      id: snapshot.id,
      postId: data?['postId'] ?? '',
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data?['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }
}