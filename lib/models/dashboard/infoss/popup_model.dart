// lib/models/popup_model.dart

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
  final String position; // "Top" atau "Normal"

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
      position: data['position'] ?? 'Normal',
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
}