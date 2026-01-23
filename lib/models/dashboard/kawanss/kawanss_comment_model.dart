// lib/models/dashboard/kawanss/kawanss_comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class KawanssCommentModel {
  final String id;
  final String comment;
  final bool deleted;
  final String kawanssId;
  final int jumlahDislike;
  final int jumlahLike;
  final int jumlahReplies;
  final String? photoURL;
  final DateTime uploadDate;
  final String userId;
  final String username;

  KawanssCommentModel({
    required this.id,
    required this.comment,
    required this.deleted,
    required this.kawanssId,
    required this.jumlahDislike,
    required this.jumlahLike,
    required this.jumlahReplies,
    this.photoURL,
    required this.uploadDate,
    required this.userId,
    required this.username,
  });

  factory KawanssCommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();

    // --- PERBAIKAN UTAMA: Helper function untuk parsing tanggal ---
    DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Gagal mem-parsing tanggal string: $dateValue. Error: $e");
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    // -------------------------------------------------------------

    return KawanssCommentModel(
      id: snapshot.id,
      comment: data?['comment'] ?? '',
      deleted: data?['deleted'] ?? false,
      kawanssId: data?['kawanssId'] ?? '',
      jumlahDislike: data?['jumlahDislike'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahReplies: data?['jumlahReplies'] ?? 0,
      photoURL: data?['photoURL'],
      uploadDate: parseSafeDate(data?['uploadDate']), // Gunakan helper function
      userId: data?['userId'] ?? '',
      username: data?['username'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'deleted': deleted,
      'kawanssId': kawanssId,
      'jumlahDislike': jumlahDislike,
      'jumlahLike': jumlahLike,
      'jumlahReplies': jumlahReplies,
      if (photoURL != null) 'photoURL': photoURL,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'userId': userId,
      'username': username,
    };
  }
}