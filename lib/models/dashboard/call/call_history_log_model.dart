import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistoryLogModel {
  final String id;
  final String channelName;
  final String callerName;
  final String callerPhotoURL;
  final bool isVideoCall;
  final String status;
  final DateTime createdAt;
  final DateTime? endedAt; // Bisa Null
  final String? adminId;
  final String? adminName;
  final Duration duration;

  CallHistoryLogModel({
    required this.id,
    required this.channelName,
    required this.callerName,
    required this.callerPhotoURL,
    required this.isVideoCall,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.adminId,
    this.adminName,
    required this.duration,
  });

  factory CallHistoryLogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    
    // 1. Helper Function yang Aman
    DateTime? parseSafeDate(dynamic dateValue) {
      if (dateValue == null) return null; // Return null jika tidak ada data
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // 2. Parse Tanggal dengan aman
    final DateTime start = parseSafeDate(data?['createdAt']) ?? DateTime.now();
    final DateTime? end = parseSafeDate(data?['endedAt']);

    // 3. Hitung Durasi (Hanya jika end time ada)
    Duration calcDuration = Duration.zero;
    if (end != null) {
      // Pastikan durasi tidak minus (jika jam server ngaco)
      var diff = end.difference(start);
      calcDuration = diff.isNegative ? Duration.zero : diff;
    }

    return CallHistoryLogModel(
      id: snapshot.id,
      channelName: data?['channelName'] ?? '',
      callerName: data?['username'] ?? 'Unknown User',
      callerPhotoURL: data?['photoURL'] ?? '',
      isVideoCall: data?['isVideoCall'] ?? false,
      status: data?['status'] ?? 'unknown',
      createdAt: start,
      endedAt: end, // Bisa null
      adminId: data?['adminId'],
      adminName: data?['adminName'] ?? data?['adminId'] ?? '-', 
      duration: calcDuration,
    );
  }
}