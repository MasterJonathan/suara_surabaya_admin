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
  final String position;

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
    required this.position,
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
      position: data['position'] ?? 'Top',
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
      'position': position,
    };
  }

  // --- COPY WITH (PENTING) ---
  BannerTopModel copyWith({
    String? id,
    String? namaBanner,
    DateTime? tanggalAktifMulai,
    DateTime? tanggalAktifSelesai,
    String? bannerImageUrl,
    bool? status,
    int? hits,
    DateTime? tanggalPosting,
    String? dipostingOleh,
    String? position,
  }) {
    return BannerTopModel(
      id: id ?? this.id,
      namaBanner: namaBanner ?? this.namaBanner,
      tanggalAktifMulai: tanggalAktifMulai ?? this.tanggalAktifMulai,
      tanggalAktifSelesai: tanggalAktifSelesai ?? this.tanggalAktifSelesai,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      status: status ?? this.status,
      hits: hits ?? this.hits,
      tanggalPosting: tanggalPosting ?? this.tanggalPosting,
      dipostingOleh: dipostingOleh ?? this.dipostingOleh,
      position: position ?? this.position,
    );
  }
}