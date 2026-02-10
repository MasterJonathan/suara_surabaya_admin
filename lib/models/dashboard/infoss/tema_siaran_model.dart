import 'package:cloud_firestore/cloud_firestore.dart';

class TemaSiaranModel {
  final String id;
  final String namaTema;
  final DateTime tanggalAktifMulai;
  final DateTime tanggalAktifSelesai;
  final String temaImageUrl;
  final bool status;
  final int hits;
  final DateTime tanggalPosting;
  final String dipostingOleh;
  final bool isDefault;

  TemaSiaranModel({
    required this.id,
    required this.namaTema,
    required this.tanggalAktifMulai,
    required this.tanggalAktifSelesai,
    required this.temaImageUrl,
    required this.status,
    required this.hits,
    required this.tanggalPosting,
    required this.dipostingOleh,
    this.isDefault = false,
  });

  factory TemaSiaranModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return TemaSiaranModel(
      id: snapshot.id,
      namaTema: data['namaTema'] ?? '',
      tanggalAktifMulai: (data['tanggalAktifMulai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalAktifSelesai: (data['tanggalAktifSelesai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      temaImageUrl: data['temaImageUrl'] ?? '',
      status: data['status'] ?? false,
      hits: data['hits'] ?? 0,
      tanggalPosting: (data['tanggalPosting'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dipostingOleh: data['dipostingOleh'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaTema': namaTema,
      'tanggalAktifMulai': Timestamp.fromDate(tanggalAktifMulai),
      'tanggalAktifSelesai': Timestamp.fromDate(tanggalAktifSelesai),
      'temaImageUrl': temaImageUrl,
      'status': status,
      'hits': hits,
      'tanggalPosting': Timestamp.fromDate(tanggalPosting),
      'dipostingOleh': dipostingOleh,
      'isDefault': isDefault,
    };
  }

  // --- METODE PENTING BARU ---
  TemaSiaranModel copyWith({
    String? id,
    String? namaTema,
    DateTime? tanggalAktifMulai,
    DateTime? tanggalAktifSelesai,
    String? temaImageUrl,
    bool? status,
    int? hits,
    DateTime? tanggalPosting,
    String? dipostingOleh,
    bool? isDefault,
  }) {
    return TemaSiaranModel(
      id: id ?? this.id,
      namaTema: namaTema ?? this.namaTema,
      tanggalAktifMulai: tanggalAktifMulai ?? this.tanggalAktifMulai,
      tanggalAktifSelesai: tanggalAktifSelesai ?? this.tanggalAktifSelesai,
      temaImageUrl: temaImageUrl ?? this.temaImageUrl,
      status: status ?? this.status,
      hits: hits ?? this.hits,
      tanggalPosting: tanggalPosting ?? this.tanggalPosting,
      dipostingOleh: dipostingOleh ?? this.dipostingOleh,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}