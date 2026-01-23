// lib/models/news_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Helper function untuk parsing tanggal yang aman
DateTime? _parseSafeTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  // Menangani format 'yyyy-MM-dd HH:mm:ss' dari screenshot
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      // Jika gagal, coba format lain jika ada
      try {
        // Contoh format lain: August 20, 2024 at 4:56:03 PM UTC+7
        // Ini memerlukan parsing yang lebih kompleks, untuk sekarang kita sederhanakan
        return DateFormat("MMMM d, yyyy 'at' h:mm:ss a 'UTC'Z").parse(value, true);
      } catch (e2) {
        print('Error parsing date string: $value. Error: $e2');
        return null;
      }
    }
  }
  return null;
}

class BeritaModel {
  final String id; // ID Dokumen
  final String category;
  final String? full; // Deskripsi lengkap
  final String? info; // Deskripsi singkat/lead
  final String? jpg10; // URL Gambar
  final String? jpg10Desc; // Deskripsi gambar
  final int jumlahComment;
  final int jumlahLike;
  final int jumlahShare;
  final int jumlahView;
  final String? pengirim;
  final DateTime? timestamp;
  final String title;
  final DateTime? uploadDate;

  BeritaModel({
    required this.id,
    required this.category,
    this.full,
    this.info,
    this.jpg10,
    this.jpg10Desc,
    required this.jumlahComment,
    required this.jumlahLike,
    required this.jumlahShare,
    required this.jumlahView,
    this.pengirim,
    this.timestamp,
    required this.title,
    this.uploadDate,
  });

  factory BeritaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    
    return BeritaModel(
      id: snapshot.id,
      category: data?['category'] ?? '',
      full: data?['full'],
      // Gunakan jpg10_desc sebagai lead jika 'info' kosong
      info: data?['info'] ?? data?['jpg10_desc'] ?? '',
      jpg10: data?['jpg10'],
      jpg10Desc: data?['jpg10_desc'],
      jumlahComment: data?['jumlahComment'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahShare: data?['jumlahShare'] ?? 0,
      jumlahView: data?['jumlahView'] ?? 0,
      pengirim: data?['pengirim'],
      timestamp: _parseSafeTimestamp(data?['timestamp']),
      title: data?['title'] ?? '',
      uploadDate: _parseSafeTimestamp(data?['uploadDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      if (full != null) 'full': full,
      if (info != null) 'info': info,
      if (jpg10 != null) 'jpg10': jpg10,
      if (jpg10Desc != null) 'jpg10_desc': jpg10Desc,
      'jumlahComment': jumlahComment,
      'jumlahLike': jumlahLike,
      'jumlahShare': jumlahShare,
      'jumlahView': jumlahView,
      if (pengirim != null) 'pengirim': pengirim,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
      'title': title,
      if (uploadDate != null) 'uploadDate': Timestamp.fromDate(uploadDate!),
    };
  }
}