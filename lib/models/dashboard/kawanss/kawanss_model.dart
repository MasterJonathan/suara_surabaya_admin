import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime? _parseSafeTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    try {
      if (value.contains('/')) return DateFormat('MM/dd/yyyy HH:mm').parse(value);
      return DateTime.parse(value);
    } catch (e) { return null; }
  }
  return null;
}

class KawanssModel {
  final String id;
  final String? accountName;
  final bool deleted;
  final String? deskripsi;
  final String? gambar;
  final int jumlahComment;
  final int jumlahLaporan;
  final int jumlahLike;
  final String? kawanssPhotoURL;
  final String? lokasi;
  final String? title;
  final DateTime uploadDate;
  final String userId;

  KawanssModel({
    required this.id, this.accountName, required this.deleted, this.deskripsi,
    this.gambar, required this.jumlahComment, required this.jumlahLaporan,
    required this.jumlahLike, this.kawanssPhotoURL, this.lokasi, this.title,
    required this.uploadDate, required this.userId,
  });

  factory KawanssModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return KawanssModel(
      id: snapshot.id,
      accountName: data?['accountName'],
      deleted: data?['deleted'] ?? false,
      deskripsi: data?['deskripsi'],
      gambar: data?['gambar'],
      jumlahComment: data?['jumlahComment'] ?? 0,
      jumlahLaporan: data?['jumlahLaporan'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      kawanssPhotoURL: data?['kawanssPhotoURL'],
      lokasi: data?['lokasi'],
      title: data?['title'],
      uploadDate: _parseSafeTimestamp(data?['uploadDate']) ?? DateTime.now(),
      userId: data?['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (accountName != null) 'accountName': accountName,
      'deleted': deleted,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (gambar != null) 'gambar': gambar,
      'jumlahComment': jumlahComment, 'jumlahLaporan': jumlahLaporan, 'jumlahLike': jumlahLike,
      if (kawanssPhotoURL != null) 'kawanssPhotoURL': kawanssPhotoURL,
      if (lokasi != null) 'lokasi': lokasi,
      if (title != null) 'title': title,
      'uploadDate': Timestamp.fromDate(uploadDate), 'userId': userId,
    };
  }
}