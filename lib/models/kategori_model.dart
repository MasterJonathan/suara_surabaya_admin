// lib/models/kategori_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class KategoriModel {
  final String id;
  final String namaKategori;
  final String jenis; // BARU: Untuk menyimpan nama koleksi (e.g., 'kategoriInfoSS')

  KategoriModel({
    required this.id,
    required this.namaKategori,
    required this.jenis, // BARU
  });

  // fromFirestore sekarang membutuhkan nama koleksi sebagai parameter
  factory KategoriModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, String collectionName) {
    final data = snapshot.data();
    String name = data?['namaKategori'] ?? data?['namaKategori1'] ?? '';
    return KategoriModel(
      id: snapshot.id,
      namaKategori: name,
      jenis: collectionName, // Simpan nama koleksi
    );
  }

  Map<String, dynamic> toFirestore() {
    // 'jenis' tidak perlu disimpan ke Firestore karena sudah direpresentasikan oleh nama koleksi
    return {
      'namaKategori': namaKategori,
    };
  }
}