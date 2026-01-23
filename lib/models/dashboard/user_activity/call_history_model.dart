// lib/models/call_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistoryModel {
  final String id;
  final bool isVideoCall;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  CallHistoryModel({
    required this.id,
    required this.isVideoCall,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory CallHistoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = (data['endTime'] as Timestamp).toDate();
    
    return CallHistoryModel(
      id: snapshot.id,
      isVideoCall: data['isVideoCall'] ?? false,
      startTime: startTime,
      endTime: endTime,
      duration: endTime.difference(startTime),
    );
  }
}