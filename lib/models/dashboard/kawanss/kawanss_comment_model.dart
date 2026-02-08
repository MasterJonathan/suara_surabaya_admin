import 'package:cloud_firestore/cloud_firestore.dart';

class KawanssCommentModel {
  final String id;
  final String comment;
  final bool deleted; // Tetap pakai nama 'deleted' di properti
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

    DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) {
        try { return DateTime.parse(dateValue); } catch (e) { return DateTime.now(); }
      }
      return DateTime.now();
    }

    return KawanssCommentModel(
      id: snapshot.id,
      comment: data?['comment'] ?? '',
      // Prioritaskan 'isDeleted', fallback ke 'deleted'
      deleted: data?['isDeleted'] ?? data?['deleted'] ?? false,
      kawanssId: data?['kawanssId'] ?? '',
      jumlahDislike: data?['jumlahDislike'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahReplies: data?['jumlahReplies'] ?? 0,
      photoURL: data?['photoURL'],
      uploadDate: parseSafeDate(data?['uploadDate']),
      userId: data?['userId'] ?? '',
      username: data?['username'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'isDeleted': deleted, // Simpan standar baru
      'deleted': deleted,   // Simpan legacy
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

  // --- COPY WITH ---
  KawanssCommentModel copyWith({
    String? id,
    String? comment,
    bool? deleted,
    String? kawanssId,
    int? jumlahDislike,
    int? jumlahLike,
    int? jumlahReplies,
    String? photoURL,
    DateTime? uploadDate,
    String? userId,
    String? username,
  }) {
    return KawanssCommentModel(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      deleted: deleted ?? this.deleted,
      kawanssId: kawanssId ?? this.kawanssId,
      jumlahDislike: jumlahDislike ?? this.jumlahDislike,
      jumlahLike: jumlahLike ?? this.jumlahLike,
      jumlahReplies: jumlahReplies ?? this.jumlahReplies,
      photoURL: photoURL ?? this.photoURL,
      uploadDate: uploadDate ?? this.uploadDate,
      userId: userId ?? this.userId,
      username: username ?? this.username,
    );
  }
}