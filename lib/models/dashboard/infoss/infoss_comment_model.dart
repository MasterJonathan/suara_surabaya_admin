import 'package:cloud_firestore/cloud_firestore.dart';

class InfossCommentModel {
  final String id;
  final String comment;
  final bool deleted; // Di UI tetap pakai nama 'deleted' biar ga ubah banyak kode UI
  final List<String>? dislikedUsers;
  final String infossId;
  final int jumlahDislike;
  final int jumlahLike;
  final int jumlahReplies;
  final List<String>? likedUsers;
  final String? photoURL;
  final DateTime uploadDate;
  final String userId;
  final String username;

  InfossCommentModel({
    required this.id,
    required this.comment,
    required this.deleted,
    this.dislikedUsers,
    required this.infossId,
    required this.jumlahDislike,
    required this.jumlahLike,
    required this.jumlahReplies,
    this.likedUsers,
    this.photoURL,
    required this.uploadDate,
    required this.userId,
    required this.username,
  });

  factory InfossCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    DateTime parseSafeDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return InfossCommentModel(
      id: snapshot.id,
      comment: data?['comment'] ?? '',
      // Prioritaskan 'isDeleted' (standar baru), fallback ke 'deleted'
      deleted: data?['isDeleted'] ?? data?['deleted'] ?? false,
      dislikedUsers: data?['dislikedUsers'] != null ? List<String>.from(data?['dislikedUsers']) : null,
      infossId: data?['infossId'] ?? '',
      jumlahDislike: data?['jumlahDislike'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahReplies: data?['jumlahReplies'] ?? 0,
      likedUsers: data?['likedUsers'] != null ? List<String>.from(data?['likedUsers']) : null,
      photoURL: data?['photoURL'],
      uploadDate: parseSafeDate(data?['uploadDate']),
      userId: data?['userId'] ?? '',
      username: data?['username'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'isDeleted': deleted, // Simpan sebagai isDeleted
      'deleted': deleted,   // Simpan juga legacy field jika perlu
      if (dislikedUsers != null) 'dislikedUsers': dislikedUsers,
      'infossId': infossId,
      'jumlahDislike': jumlahDislike,
      'jumlahLike': jumlahLike,
      'jumlahReplies': jumlahReplies,
      if (likedUsers != null) 'likedUsers': likedUsers,
      if (photoURL != null) 'photoURL': photoURL,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'userId': userId,
      'username': username,
    };
  }

  // --- COPY WITH ---
  InfossCommentModel copyWith({
    String? id,
    String? comment,
    bool? deleted,
    List<String>? dislikedUsers,
    String? infossId,
    int? jumlahDislike,
    int? jumlahLike,
    int? jumlahReplies,
    List<String>? likedUsers,
    String? photoURL,
    DateTime? uploadDate,
    String? userId,
    String? username,
  }) {
    return InfossCommentModel(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      deleted: deleted ?? this.deleted,
      dislikedUsers: dislikedUsers ?? this.dislikedUsers,
      infossId: infossId ?? this.infossId,
      jumlahDislike: jumlahDislike ?? this.jumlahDislike,
      jumlahLike: jumlahLike ?? this.jumlahLike,
      jumlahReplies: jumlahReplies ?? this.jumlahReplies,
      likedUsers: likedUsers ?? this.likedUsers,
      photoURL: photoURL ?? this.photoURL,
      uploadDate: uploadDate ?? this.uploadDate,
      userId: userId ?? this.userId,
      username: username ?? this.username,
    );
  }
}