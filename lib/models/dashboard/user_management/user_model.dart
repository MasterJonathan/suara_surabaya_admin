import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String role;
  final Map<String, String> hakAkses;
  final bool status; // <-- Tipe data sudah benar (bool)
  final DateTime joinDate;
  final String email;
  final String nama;
  final String? alamat;
  final String? jenisKelamin;
  final int jumlahComment;
  final int jumlahKontributor;
  final int jumlahLike;
  final int jumlahShare;
  final String? nomorHp;
  final String? photoURL;
  final String? tanggalLahir;
  final List<Map<String, dynamic>>? aktivitas;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.hakAkses,
    required this.status, // <-- Menerima bool
    required this.joinDate,
    required this.email,
    required this.nama,
    required this.jumlahComment,
    required this.jumlahKontributor,
    required this.jumlahLike,
    required this.jumlahShare,
    this.alamat,
    this.jenisKelamin,
    this.nomorHp,
    this.photoURL,
    this.tanggalLahir,
    this.aktivitas,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    Map<String, String> parsedHakAkses = {};
    if (data?['hakAkses'] is Map) {
      // Pastikan semua value adalah String
      (data?['hakAkses'] as Map).forEach((key, value) {
        if (value is String) {
          parsedHakAkses[key] = value;
        }
      });
    }

    // --- LOGIKA KONVERSI STATUS YANG BENAR ---
    bool parsedStatus;
    // Prioritas 1: Cek jika ada field 'status' bertipe bool
    if (data?['status'] is bool) {
      parsedStatus = data?['status'];
    }
    // Prioritas 2: Cek jika ada field 'status' bertipe String "Aktif"
    else if (data?['status'] is String) {
      parsedStatus = data?['status'] == 'Aktif';
    }
    // Fallback: Jika tidak ada, anggap tidak aktif
    else {
      parsedStatus = false;
    }
    // ------------------------------------

    List<Map<String, dynamic>>? parsedAktivitas;
    if (data?['aktivitas'] is List) {
      parsedAktivitas = List<Map<String, dynamic>>.from(
        (data?['aktivitas'] as List)
            .where((item) => item is Map)
            .cast<Map<String, dynamic>>(),
      );
    }

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return UserModel(
      id: snapshot.id,
      email: data?['email'] ?? '',
      nama: data?['nama'] ?? '',
      username: data?['username'] ?? data?['nama'] ?? '',
      role: data?['role'] ?? 'User',
       hakAkses: parsedHakAkses,
      status: parsedStatus, // <-- Gunakan boolean yang sudah di-parse
      joinDate: parseDate(data?['joinDate'] ?? data?['waktu']),
      jumlahComment: data?['jumlahComment'] ?? 0,
      jumlahKontributor: data?['jumlahKontributor'] ?? 0,
      jumlahLike: data?['jumlahLike'] ?? 0,
      jumlahShare: data?['jumlahShare'] ?? 0,
      alamat: data?['alamat'],
      jenisKelamin: data?['jenis_kelamin'],
      nomorHp: data?['nomor_hp'],
      photoURL: data?['photoURL'],
      tanggalLahir: data?['tanggal_lahir'],
      aktivitas: parsedAktivitas,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'hakAkses': hakAkses,
      'status': status, // <-- Simpan sebagai boolean
      'joinDate': Timestamp.fromDate(joinDate),
      'email': email,
      'nama': nama,
      'jumlahComment': jumlahComment,
      'jumlahKontributor': jumlahKontributor,
      'jumlahLike': jumlahLike,
      'jumlahShare': jumlahShare,
      if (alamat != null) 'alamat': alamat,
      if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
      if (nomorHp != null) 'nomor_hp': nomorHp,
      if (photoURL != null) 'photoURL': photoURL,
      if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
      if (aktivitas != null) 'aktivitas': aktivitas,
    };
  }
}
