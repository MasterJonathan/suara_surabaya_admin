import 'package:cloud_firestore/cloud_firestore.dart';

class InfossCommentModel {
  final String id;
  final String comment;
  final bool deleted;
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
      if (dateValue == null) {
        return DateTime.now(); // Fallback jika data null
      }
      if (dateValue is Timestamp) {
        return dateValue.toDate(); // Cara yang benar dan paling umum
      }
      if (dateValue is String) {
        // Coba parsing dari format ISO 8601 (seperti di screenshot Anda)
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Gagal mem-parsing tanggal string: $dateValue. Error: $e");
          return DateTime.now(); // Fallback jika parsing gagal
        }
      }
      // Fallback jika tipe data tidak dikenal
      return DateTime.now();
    }

    return InfossCommentModel(
      id: snapshot.id,
      comment: data?['comment'] ?? '',
      deleted: data?['deleted'] ?? false,
      dislikedUsers:
          data?['dislikedUsers'] != null
              ? List<String>.from(data?['dislikedUsers'])
              : null,
      infossId: data?['infossId'] ?? '',
      jumlahDislike: data?['jumlahDislike'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahReplies: data?['jumlahReplies'] ?? 0,
      likedUsers:
          data?['likedUsers'] != null
              ? List<String>.from(data?['likedUsers'])
              : null,
      photoURL: data?['photoURL'],
      uploadDate: parseSafeDate(data?['uploadDate']),
      userId: data?['userId'] ?? '',
      username: data?['username'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'deleted': deleted,
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
}
