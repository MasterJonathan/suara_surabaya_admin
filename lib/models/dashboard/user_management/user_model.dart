import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String role;
  final Map<String, String> hakAkses;
  final bool status;
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
    required this.status,
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

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    Map<String, String> parsedHakAkses = {};
    if (data?['hakAkses'] is Map) {
      (data?['hakAkses'] as Map).forEach((key, value) { if (value is String) parsedHakAkses[key] = value; });
    }

    bool parsedStatus = false;
    if (data?['status'] is bool) parsedStatus = data?['status'];
    else if (data?['status'] is String) parsedStatus = data?['status'] == 'Aktif';

    List<Map<String, dynamic>>? parsedAktivitas;
    if (data?['aktivitas'] is List) {
      parsedAktivitas = List<Map<String, dynamic>>.from((data?['aktivitas'] as List).where((item) => item is Map).cast<Map<String, dynamic>>());
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
      status: parsedStatus,
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
      'status': status,
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

  // --- COPY WITH (Untuk Update Lokal) ---
  UserModel copyWith({
    String? id,
    String? username,
    String? role,
    Map<String, String>? hakAkses,
    bool? status,
    DateTime? joinDate,
    String? email,
    String? nama,
    int? jumlahComment,
    int? jumlahKontributor,
    int? jumlahLike,
    int? jumlahShare,
    String? alamat,
    String? jenisKelamin,
    String? nomorHp,
    String? photoURL,
    String? tanggalLahir,
    List<Map<String, dynamic>>? aktivitas,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      hakAkses: hakAkses ?? this.hakAkses,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      email: email ?? this.email,
      nama: nama ?? this.nama,
      jumlahComment: jumlahComment ?? this.jumlahComment,
      jumlahKontributor: jumlahKontributor ?? this.jumlahKontributor,
      jumlahLike: jumlahLike ?? this.jumlahLike,
      jumlahShare: jumlahShare ?? this.jumlahShare,
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      nomorHp: nomorHp ?? this.nomorHp,
      photoURL: photoURL ?? this.photoURL,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      aktivitas: aktivitas ?? this.aktivitas,
    );
  }
}