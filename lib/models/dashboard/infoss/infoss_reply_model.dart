// lib/models/dashboard/infoss/infoss_reply_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class InfossReplyModel {
  final String id;
  final String comment;
  final bool deleted;
  final String parentCommentId; // ID dari komentar induk
  final DateTime uploadDate;
  final String userId;
  final String username;
  final String? photoURL;

  InfossReplyModel({
    required this.id,
    required this.comment,
    required this.deleted,
    required this.parentCommentId,
    required this.uploadDate,
    required this.userId,
    required this.username,
    this.photoURL,
  });

  factory InfossReplyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();

    DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
      return DateTime.now();
    }

    return InfossReplyModel(
      id: snapshot.id,
      comment: data?['comment'] ?? '',
      deleted: data?['deleted'] ?? false,
      parentCommentId: data?['parentCommentId'] ?? '',
      uploadDate: parseSafeDate(data?['uploadDate']),
      userId: data?['userId'] ?? '',
      username: data?['username'] ?? '',
      photoURL: data?['photoURL'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'deleted': deleted,
      'parentCommentId': parentCommentId,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'userId': userId,
      'username': username,
      if (photoURL != null) 'photoURL': photoURL,
    };
  }
}