// lib/models/activity_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { posting, like, call, unknown }

class ActivityModel {
  final String id;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  ActivityModel({
    required this.id,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  // Factory ini adalah contoh, Anda perlu menyesuaikannya dengan data asli di Firestore
  factory ActivityModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    ActivityType activityType;
    // Konversi dari String di Firestore ke Enum di Dart
    switch (data['type'] as String?) {
      case 'like':
        activityType = ActivityType.like;
        break;
      case 'call':
        activityType = ActivityType.call;
        break;
      case 'posting':
        activityType = ActivityType.posting;
        break;
      default:
        activityType = ActivityType.unknown;
    }

    return ActivityModel(
      id: snapshot.id,
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: activityType,
    );
  }
}