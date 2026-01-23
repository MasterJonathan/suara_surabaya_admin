import 'dart:typed_data';

import 'package:suara_surabaya_admin/core/utils/constants.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_reply_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_activity/call_history_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/banner_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/popup_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/tema_siaran_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/models/kategori_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:suara_surabaya_admin/models/kawanss_report_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/berita/berita_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/settings_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/user_management/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<UserModel>> getUsersStream() {
    return _db
        .collection(USERS_COLLECTION)
        .orderBy('nama', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final docRef = _db.collection(USERS_COLLECTION).doc(uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      return UserModel.fromFirestore(docSnap, null);
    }
    return null;
  }

  Future<void> setUserProfile(UserModel user) {
    return _db
        .collection(USERS_COLLECTION)
        .doc(user.id)
        .set(user.toFirestore());
  }

  Future<void> addUser(UserModel user) {
    return _db
        .collection(USERS_COLLECTION)
        .doc(user.id)
        .set(user.toFirestore());
  }

  Future<void> updateUser(UserModel user) {
    return _db
        .collection(USERS_COLLECTION)
        .doc(user.id)
        .update(user.toFirestore());
  }

  Future<void> updateUserPartial(String userId, Map<String, dynamic> data) {
    return _db.collection(USERS_COLLECTION).doc(userId).update(data);
  }

  Future<void> deleteUser(String userId) {
    return _db.collection(USERS_COLLECTION).doc(userId).delete();
  }

  Stream<List<KawanssModel>> getKawanssStream() {
    return _db
        .collection(KAWANSS_COLLECTION)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<List<KawanssModel>> getKawanssInDateRange(DateTime startDate, DateTime endDate) async {
    // Query efisien menggunakan index uploadDate
    final querySnapshot = await _db
        .collection(KAWANSS_COLLECTION)
        .where('uploadDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return querySnapshot.docs
        .map((doc) => KawanssModel.fromFirestore(doc, null))
        .toList();
  }

  Future<DocumentReference> addKawanss(KawanssModel kawanss) {
    return _db.collection(KAWANSS_COLLECTION).add(kawanss.toFirestore());
  }

  Future<void> updateKawanss(KawanssModel kawanss) {
    return _db
        .collection(KAWANSS_COLLECTION)
        .doc(kawanss.id)
        .update(kawanss.toFirestore());
  }

  Future<void> deleteKawanss(String kawanssId) {
    return _db.collection(KAWANSS_COLLECTION).doc(kawanssId).delete();
  }

  Stream<List<KawanssCommentModel>> getKawanssCommentsStream() {
    return _db
        .collection('kawanssComments') // Nama koleksi root untuk komentar Kawan SS
        .orderBy('uploadDate', descending: true)
        .limit(100) // Batasi untuk performa awal
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KawanssCommentModel.fromFirestore(doc, null))
            .toList());
  }

  Future<void> softDeleteKawanssComment(String commentId, bool isDeleted) {
    return _db.collection('kawanssComments').doc(commentId).update({'deleted': isDeleted});
  }
  

  Stream<List<KawanSSReportModel>> getKontributorsStream() {
    return _db
        .collection(KONTRIBUTOR_COLLECTION)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanSSReportModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<DocumentReference> addKontributor(KawanSSReportModel kontributor) {
    return _db
        .collection(KONTRIBUTOR_COLLECTION)
        .add(kontributor.toFirestore());
  }

  Future<void> updateKontributor(KawanSSReportModel kontributor) {
    return _db
        .collection(KONTRIBUTOR_COLLECTION)
        .doc(kontributor.id)
        .update(kontributor.toFirestore());
  }

  Future<void> deleteKontributor(String kontributorId) {
    return _db.collection(KONTRIBUTOR_COLLECTION).doc(kontributorId).delete();
  }

  Stream<List<BeritaModel>> getNewsStream() {
    return _db
        .collection(NEWS_COLLECTION)
        .where('title', isNotEqualTo: null)
        .where('title', isNotEqualTo: '')
        .orderBy('title')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BeritaModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<DocumentReference> addNews(BeritaModel news) {
    return _db.collection(NEWS_COLLECTION).add(news.toFirestore());
  }

  Future<void> updateNews(BeritaModel news) {
    return _db
        .collection(NEWS_COLLECTION)
        .doc(news.id)
        .update(news.toFirestore());
  }

  Future<void> deleteNews(String newsId) {
    return _db.collection(NEWS_COLLECTION).doc(newsId).delete();
  }

  Stream<List<BannerTopModel>> getBannersStream() {
    return _db
        .collection('bannerTop')
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BannerTopModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<DocumentReference> addBanner(BannerTopModel banner) {
    return _db.collection('bannerTop').add(banner.toFirestore());
  }

  Future<void> updateBanner(BannerTopModel banner) {
    return _db
        .collection('bannerTop')
        .doc(banner.id)
        .update(banner.toFirestore());
  }

  Future<void> deleteBanner(String bannerId) {
    return _db.collection('bannerTop').doc(bannerId).delete();
  } 

  // Mengambil data dari koleksi tertentu
  Stream<List<KategoriModel>> getKategoriStream(String collectionName) {
    return _db
        .collection(collectionName)
        .orderBy('namaKategori')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  // Teruskan collectionName ke fromFirestore
                  .map(
                    (doc) => KategoriModel.fromFirestore(doc, collectionName),
                  )
                  .toList(),
        );
  }

  // Menambah data ke koleksi tertentu
  Future<void> addKategori(String collectionName, KategoriModel kategori) {
    return _db.collection(collectionName).add(kategori.toFirestore());
  }

  // Menghapus data dari koleksi tertentu
  Future<void> deleteKategori(String collectionName, String kategoriId) {
    return _db.collection(collectionName).doc(kategoriId).delete();
  }

  // --- Metode untuk Koleksi Infoss --- (BARU)

  // --- FUNGSI BARU: Fetch Batch dengan Pagination ---
  Future<QuerySnapshot<Map<String, dynamic>>> getInfossBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db.collection(INFOSS_COLLECTION)
        .where('uploadDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<InfossModel>> getInfossStream() {
    return _db
        .collection(INFOSS_COLLECTION)
        .orderBy(
          'uploadDate',
          descending: true,
        ) // Urutkan berdasarkan tanggal terbaru
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<List<InfossModel>> getInfossInDateRange(DateTime startDate, DateTime endDate) async {
    // Query Server-Side yang efisien dan hemat biaya
    final querySnapshot = await _db
        .collection(INFOSS_COLLECTION)
        .where('uploadDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return querySnapshot.docs
        .map((doc) => InfossModel.fromFirestore(doc, null))
        .toList();
  }

  Future<void> addInfoss(InfossModel infoss) async {
    // Langkah 1: Buat dokumen baru dengan .add() untuk mendapatkan ID unik.
    // Kita kirim data tanpa field 'id' terlebih dahulu.
    DocumentReference docRef = await _db
        .collection(INFOSS_COLLECTION)
        .add(infoss.toFirestore());

    // Langkah 2: Update dokumen yang baru saja dibuat dengan ID-nya sendiri.
    // Kita gunakan model asli yang sudah punya 'id' kosong, lalu kita update.
    await docRef.update({'id': docRef.id});
  }

  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    String fileName,
  ) async {
    try {
      // Buat referensi ke lokasi di Firebase Storage
      Reference ref = _storage.ref().child(childName).child(fileName);

      // Tentukan metadata untuk file (penting untuk web agar bisa ditampilkan)
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload file
      UploadTask uploadTask = ref.putData(file, metadata);

      // Tunggu hingga upload selesai
      TaskSnapshot snapshot = await uploadTask;

      // Dapatkan URL download
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print("Error uploading image: $e");
      throw Exception("Gagal meng-upload gambar.");
    }
  }

  Future<void> updateInfoss(InfossModel infoss) {
    return _db
        .collection(INFOSS_COLLECTION)
        .doc(infoss.id)
        .update(infoss.toFirestore());
  }

  Future<void> deleteInfoss(String infossId) {
    return _db.collection(INFOSS_COLLECTION).doc(infossId).delete();
  }


  // Mengambil SEMUA komentar Info SS untuk halaman admin
  Stream<List<InfossCommentModel>> getInfossCommentsStream() {
    return _db
        .collection('infossComments') // Koleksi root
        .orderBy('uploadDate', descending: true)
        .limit(100) // Batasi untuk performa
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InfossCommentModel.fromFirestore(doc, null))
            .toList());
  }

  // Soft delete komentar Info SS
  Future<void> softDeleteInfossComment(String commentId, bool isDeleted) {
    return _db.collection('infossComments').doc(commentId).update({'deleted': isDeleted});
  }

  Stream<List<InfossCommentModel>> getCommentsStreamForInfoss(String infossId) {
    // Query ke koleksi root 'infossComments' dan filter berdasarkan infossId
    return _db
        .collection('infossComments') // <-- Ubah ke koleksi root
        .where('infossUid', isEqualTo: infossId) // <-- Tambahkan filter ini
        .orderBy('uploadDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Stream<List<InfossReplyModel>> getRepliesStreamForComment(String infossId, String commentId) {
    return _db
        .collection('infossComments') // Koleksi komentar root
        .doc(commentId)               // Dokumen komentar spesifik
        .collection('Replies')        // Sub-koleksi balasan
        .orderBy('uploadDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InfossReplyModel.fromFirestore(doc, null))
            .toList());
  }

  Future<void> updateInfossComment(InfossCommentModel comment) {
    return _db
        .collection(INFOSS_COMMENTS_COLLECTION)
        .doc(comment.id)
        .update(comment.toFirestore());
  }

  Future<void> deleteInfossComment(String commentId) {
    return _db.collection(INFOSS_COMMENTS_COLLECTION).doc(commentId).delete();
  }

  Future<SettingsModel?> getSettings() async {
    final docRef = _db.collection('settings').doc('appConfig');
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      return SettingsModel.fromFirestore(docSnap, null);
    } else {
      return null;
    }
  }

  Future<void> updateSettings(SettingsModel settings) {
    return _db
        .collection('settings')
        .doc('appConfig')
        .set(settings.toFirestore());
  }

  Stream<List<KawanssModel>> getPostsByUser(String userId) {
    return _db
        .collection(KAWANSS_COLLECTION)
        .where('userId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Stream<List<CallHistoryModel>> getCallHistoryByUser(String userId) {
    // Firestore tidak bisa query 'where array contains' dengan mudah untuk ini.
    // Di aplikasi nyata, Anda mungkin akan query koleksi 'calls'
    // where('userId', isEqualTo: userId)
    return Stream.value([]); // Kembalikan stream kosong untuk sekarang
  }

  Future<List<UserModel>> getUsersInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _db
            .collection(USERS_COLLECTION)
            .where(
              'joinDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where('joinDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc, null))
        .toList();
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    final totalUsers =
        (await _db.collection(USERS_COLLECTION).count().get()).count ?? 0;

    final allUsersSnapshot = await _db.collection(USERS_COLLECTION).get();

    int newUsersCount = 0;
    int previousNewUsersCount = 0;

    for (var doc in allUsersSnapshot.docs) {
      final user = UserModel.fromFirestore(doc, null);
      if (user.joinDate.isAfter(thirtyDaysAgo)) {
        newUsersCount++;
      }
      if (user.joinDate.isAfter(sixtyDaysAgo) &&
          user.joinDate.isBefore(thirtyDaysAgo)) {
        previousNewUsersCount++;
      }
    }

    double newUsersChange = 0;
    if (previousNewUsersCount > 0) {
      newUsersChange =
          ((newUsersCount - previousNewUsersCount) / previousNewUsersCount) *
          100;
    } else if (newUsersCount > 0) {
      newUsersChange = 100.0;
    }

    final newsCount =
        (await _db.collection(NEWS_COLLECTION).count().get()).count ?? 0;
    final kawanssCount =
        (await _db.collection(KAWANSS_COLLECTION).count().get()).count ?? 0;
    final kontributorCount =
        (await _db.collection(KONTRIBUTOR_COLLECTION).count().get()).count ?? 0;
    final totalPosts = newsCount + kawanssCount + kontributorCount;

    int newPosts = 0;
    final collections = [
      {'name': NEWS_COLLECTION, 'field': 'uploadDate'},
      {'name': KAWANSS_COLLECTION, 'field': 'uploadDate'},
      {'name': KONTRIBUTOR_COLLECTION, 'field': 'uploadDate'},
    ];
    for (var collectionInfo in collections) {
      final snapshot = await _db.collection(collectionInfo['name']!).get();
      for (var doc in snapshot.docs) {
        final tsField = doc.data()[collectionInfo['field']!];
        if (tsField is Timestamp) {
          final date = tsField.toDate();
          if (date.isAfter(thirtyDaysAgo)) newPosts++;
        }
      }
    }

    return {
      'totalUsers': totalUsers,
      'newUsers': newUsersCount,
      'newUsersChange': newUsersChange,
      'totalPosts': totalPosts,
      'newPosts': newPosts,
    };
  }

  Future<List<InfossModel>> getTopTenPosts() async {
    final snapshot =
        await _db
            .collection(INFOSS_COLLECTION)
            .orderBy('jumlahView', descending: true)
            .limit(10)
            .get();

    return snapshot.docs
        .map((doc) => InfossModel.fromFirestore(doc, null))
        .toList();
  }

  Future<List<DateTime>> getTrafficDataInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final snapshot =
        await _db
            .collection('view_analytics')
            .where('timestamp', isGreaterThanOrEqualTo: startTime)
            .where('timestamp', isLessThanOrEqualTo: endTime)
            .get();

    final List<DateTime> timestamps = [];
    for (var doc in snapshot.docs) {
      try {
        final tsField = doc.get('timestamp');
        if (tsField is Timestamp) {
          timestamps.add(tsField.toDate());
        }
      } catch (e) {
        print(
          "Melewatkan dokumen dengan format timestamp tidak valid: ${doc.id}. Error: $e",
        );
      }
    }
    return timestamps;
  }

  Future<List<DateTime>> getPostsTraffic(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final List<DateTime> timestamps = [];
    final collections = [
      {'name': NEWS_COLLECTION, 'field': 'tanggalPosting'},
      {'name': KAWANSS_COLLECTION, 'field': 'uploadDate'},
      {'name': KONTRIBUTOR_COLLECTION, 'field': 'uploadDate'},
    ];

    for (var collectionInfo in collections) {
      final snapshot =
          await _db
              .collection(collectionInfo['name']!)
              .where(
                collectionInfo['field']!,
                isGreaterThanOrEqualTo: startTime,
              )
              .where(collectionInfo['field']!, isLessThanOrEqualTo: endTime)
              .get();

      for (var doc in snapshot.docs) {
        final tsField = doc.data()[collectionInfo['field']!];
        if (tsField is Timestamp) {
          timestamps.add(tsField.toDate());
        }
      }
    }
    return timestamps;
  }

  Future<List<DateTime>> getNewUsersTraffic(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final List<DateTime> timestamps = [];
    final snapshot = await _db.collection(USERS_COLLECTION).get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('aktivitas') && data['aktivitas'] is List) {
        final activities = data['aktivitas'] as List;
        final registrationActivity = activities.firstWhere(
          (activity) =>
              activity is Map &&
              activity['namaAktivitas'] == 'User registration',
          orElse: () => null,
        );

        if (registrationActivity != null &&
            registrationActivity.containsKey('waktu')) {
          try {
            final joinTimestamp = registrationActivity['waktu'] as Timestamp;
            final joinDate = joinTimestamp.toDate();

            if (joinDate.isAfter(startTime) && joinDate.isBefore(endTime)) {
              timestamps.add(joinDate);
            }
          } catch (e) {
            print(
              "Gagal memproses waktu untuk user ${doc.id}: ${registrationActivity['waktu']}. Error: $e",
            );
          }
        }
      }
    }
    return timestamps;
  }

  Stream<List<TemaSiaranModel>> getTemaSiaranStream() {
    return _db
        .collection('temaSiaran') // Nama koleksi di Firestore
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TemaSiaranModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<DocumentReference> addTemaSiaran(TemaSiaranModel tema) {
    return _db.collection('temaSiaran').add(tema.toFirestore());
  }

  Future<void> updateTemaSiaran(TemaSiaranModel tema) {
    return _db.collection('temaSiaran').doc(tema.id).update(tema.toFirestore());
  }

  Future<void> deleteTemaSiaran(String temaId) {
    return _db.collection('temaSiaran').doc(temaId).delete();
  }

  Future<void> setTemaSiaranAsDefault(String newDefaultId) async {
    // Dapatkan semua tema yang saat ini menjadi default (seharusnya hanya ada satu)
    final querySnapshot =
        await _db
            .collection('temaSiaran')
            .where('isDefault', isEqualTo: true)
            .get();

    // Gunakan batched write untuk efisiensi dan konsistensi data
    WriteBatch batch = _db.batch();

    // 1. Nonaktifkan semua default yang lama
    for (final doc in querySnapshot.docs) {
      if (doc.id != newDefaultId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    // 2. Aktifkan default yang baru
    final newDefaultRef = _db.collection('temaSiaran').doc(newDefaultId);
    batch.update(newDefaultRef, {'isDefault': true});

    // Jalankan semua operasi dalam satu batch
    await batch.commit();
  }

  // --- Metode untuk Koleksi Pop Up --- (BARU)
  Stream<List<PopUpModel>> getPopUpsStream() {
    return _db
        .collection('popups') // Nama koleksi di Firestore
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PopUpModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<DocumentReference> addPopUp(PopUpModel popUp) {
    return _db.collection('popups').add(popUp.toFirestore());
  }

  Future<void> updatePopUp(PopUpModel popUp) {
    return _db.collection('popups').doc(popUp.id).update(popUp.toFirestore());
  }

  Future<void> deletePopUp(String popUpId) {
    return _db.collection('popups').doc(popUpId).delete();
  }
}
