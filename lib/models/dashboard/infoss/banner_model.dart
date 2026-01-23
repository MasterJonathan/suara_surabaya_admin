// lib/models/banner_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BannerTopModel {
  final String id;
  final String namaBanner;
  final DateTime tanggalAktifMulai;
  final DateTime tanggalAktifSelesai;
  final String bannerImageUrl;
  final bool status;
  final int hits;
  final DateTime tanggalPosting;
  final String dipostingOleh;
  final String position; // <-- FIELD BARU (e.g., "Top" atau "Normal")

  BannerTopModel({
    required this.id,
    required this.namaBanner,
    required this.tanggalAktifMulai,
    required this.tanggalAktifSelesai,
    required this.bannerImageUrl,
    required this.status,
    required this.hits,
    required this.tanggalPosting,
    required this.dipostingOleh,
    required this.position, // <-- TAMBAHKAN DI CONSTRUCTOR
  });

  factory BannerTopModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return BannerTopModel(
      id: snapshot.id,
      namaBanner: data['namaBanner'] ?? '',
      tanggalAktifMulai: (data['tanggalAktifMulai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalAktifSelesai: (data['tanggalAktifSelesai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bannerImageUrl: data['bannerImageUrl'] ?? '',
      status: data['status'] ?? false,
      hits: data['hits'] ?? 0,
      tanggalPosting: (data['tanggalPosting'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dipostingOleh: data['dipostingOleh'] ?? '',
      position: data['position'] ?? 'Top', // <-- AMBIL DARI FIRESTORE, default 'Top'
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaBanner': namaBanner,
      'tanggalAktifMulai': Timestamp.fromDate(tanggalAktifMulai),
      'tanggalAktifSelesai': Timestamp.fromDate(tanggalAktifSelesai),
      'bannerImageUrl': bannerImageUrl,
      'status': status,
      'hits': hits,
      'tanggalPosting': Timestamp.fromDate(tanggalPosting),
      'dipostingOleh': dipostingOleh,
      'position': position, // <-- SIMPAN KE FIRESTORE
    };
  }
}