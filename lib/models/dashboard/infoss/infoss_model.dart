// lib/models/dashboard/infoss/infoss_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Helper function untuk parsing tanggal yang aman
DateTime _parseSafeTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    try {
      return DateFormat('MM/dd/yyyy HH:mm').parse(value);
    } catch (e) {
      try {
        return DateTime.parse(value);
      } catch (e2) {
        print('Error parsing date string: $value. Error: $e2');
        return DateTime.now();
      }
    }
  }
  return DateTime.now();
}

class InfossModel {
  final String id;
  final String? detail;
  final String? gambar;
  final String judul;
  final int jumlahComment;
  final int jumlahLike;
  final int jumlahShare;
  final int jumlahView;
  final String kategori;
  final double? latitude;
  final String? location;
  final double? longitude;
  final DateTime uploadDate;

  InfossModel({
    required this.id,
    this.detail,
    this.gambar,
    required this.judul,
    required this.jumlahComment,
    required this.jumlahLike,
    required this.jumlahShare,
    required this.jumlahView,
    required this.kategori,
    this.latitude,
    this.location,
    this.longitude,
    required this.uploadDate,
  });

  factory InfossModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    
    return InfossModel(
      id: snapshot.id,
      detail: data?['detail'],
      gambar: data?['gambar'],
      judul: data?['judul'] ?? data?['title'] ?? '',
      jumlahComment: data?['jumlahComment'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahShare: data?['jumlahShare'] ?? 0,
      jumlahView: data?['jumlahView'] ?? 0,
      kategori: data?['kategori'] ?? '',
      latitude: (data?['latitude'] as num?)?.toDouble(),
      location: data?['location'],
      longitude: (data?['longitude'] as num?)?.toDouble(),
      uploadDate: _parseSafeTimestamp(data?['uploadDate']),
    );
  }

  // --- PERBAIKAN UTAMA DI SINI ---
  Map<String, dynamic> toFirestore() {
    return {
      'id': id, // <-- Tambahkan ini
      'detail': detail,
      'gambar': gambar,
      'judul': judul,
      'jumlahComment': jumlahComment,
      'jumlahLike': jumlahLike,
      'jumlahShare': jumlahShare,
      'jumlahView': jumlahView,
      'kategori': kategori,
      'latitude': latitude, // <-- Pastikan ini ada (bisa null)
      'location': location,
      'longitude': longitude, // <-- Pastikan ini ada (bisa null)
      'uploadDate': Timestamp.fromDate(uploadDate),
    };
  }

  // --- TAMBAHKAN METODE INI ---
  InfossModel copyWith({
    String? id,
    String? detail,
    String? gambar,
    String? judul,
    int? jumlahComment,
    int? jumlahLike,
    int? jumlahShare,
    int? jumlahView,
    String? kategori,
    double? latitude,
    String? location,
    double? longitude,
    DateTime? uploadDate,
  }) {
    return InfossModel(
      id: id ?? this.id,
      detail: detail ?? this.detail,
      gambar: gambar ?? this.gambar,
      judul: judul ?? this.judul,
      jumlahComment: jumlahComment ?? this.jumlahComment,
      jumlahLike: jumlahLike ?? this.jumlahLike,
      jumlahShare: jumlahShare ?? this.jumlahShare,
      jumlahView: jumlahView ?? this.jumlahView,
      kategori: kategori ?? this.kategori,
      latitude: latitude ?? this.latitude,
      location: location ?? this.location,
      longitude: longitude ?? this.longitude,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }
  // ---------------------------
}