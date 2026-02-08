import 'package:cloud_firestore/cloud_firestore.dart';

class PopUpModel {
  final String id;
  final String namaPopUp;
  final DateTime tanggalAktifMulai;
  final DateTime tanggalAktifSelesai;
  final String popUpImageUrl;
  final bool status;
  final int hits;
  final DateTime tanggalPosting;
  final String dipostingOleh;
  final String position;

  PopUpModel({
    required this.id,
    required this.namaPopUp,
    required this.tanggalAktifMulai,
    required this.tanggalAktifSelesai,
    required this.popUpImageUrl,
    required this.status,
    required this.hits,
    required this.tanggalPosting,
    required this.dipostingOleh,
    required this.position,
  });

  factory PopUpModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return PopUpModel(
      id: snapshot.id,
      namaPopUp: data['namaPopUp'] ?? '',
      tanggalAktifMulai: (data['tanggalAktifMulai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalAktifSelesai: (data['tanggalAktifSelesai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      popUpImageUrl: data['popUpImageUrl'] ?? '',
      status: data['status'] ?? false,
      hits: data['hits'] ?? 0,
      tanggalPosting: (data['tanggalPosting'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dipostingOleh: data['dipostingOleh'] ?? '',
      position: data['position'] ?? 'Square',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaPopUp': namaPopUp,
      'tanggalAktifMulai': Timestamp.fromDate(tanggalAktifMulai),
      'tanggalAktifSelesai': Timestamp.fromDate(tanggalAktifSelesai),
      'popUpImageUrl': popUpImageUrl,
      'status': status,
      'hits': hits,
      'tanggalPosting': Timestamp.fromDate(tanggalPosting),
      'dipostingOleh': dipostingOleh,
      'position': position,
    };
  }

  // --- METODE COPY WITH ---
  PopUpModel copyWith({
    String? id,
    String? namaPopUp,
    DateTime? tanggalAktifMulai,
    DateTime? tanggalAktifSelesai,
    String? popUpImageUrl,
    bool? status,
    int? hits,
    DateTime? tanggalPosting,
    String? dipostingOleh,
    String? position,
  }) {
    return PopUpModel(
      id: id ?? this.id,
      namaPopUp: namaPopUp ?? this.namaPopUp,
      tanggalAktifMulai: tanggalAktifMulai ?? this.tanggalAktifMulai,
      tanggalAktifSelesai: tanggalAktifSelesai ?? this.tanggalAktifSelesai,
      popUpImageUrl: popUpImageUrl ?? this.popUpImageUrl,
      status: status ?? this.status,
      hits: hits ?? this.hits,
      tanggalPosting: tanggalPosting ?? this.tanggalPosting,
      dipostingOleh: dipostingOleh ?? this.dipostingOleh,
      position: position ?? this.position,
    );
  }
}