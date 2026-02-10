import 'dart:typed_data';

import 'package:suara_surabaya_admin/core/utils/constants.dart';
import 'package:suara_surabaya_admin/models/dashboard/call/call_history_log_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_reply_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
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

  // ===========================================================================
  // USER MANAGEMENT
  // ===========================================================================

  // 1. Fetch Murni Pagination (Tanpa Filter Tanggal)
  Future<QuerySnapshot<Map<String, dynamic>>> getAllUsersBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('joinDate', descending: true); // Urutkan user baru diatas

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal Join
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .where(
          'joinDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('joinDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('joinDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 3. Stream Realtime untuk Live Monitoring User Baru (Limit 50)
  Stream<List<UserModel>> getUsersLiveStream({int limit = 50}) {
    return _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('joinDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Stream<List<UserModel>> getUsersStream() {
    return _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
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

    // Pastikan user ada dan tidak terhapus
    if (docSnap.exists) {
      final data = docSnap.data();
      if (data != null && data['isDeleted'] == true) return null;
      return UserModel.fromFirestore(docSnap, null);
    }
    return null;
  }

  Future<void> setUserProfile(UserModel user) {
    // Set biasanya menimpa dokumen, jadi kita harus pastikan meta data tetap ada
    final data = user.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    // Jika dokumen baru, set createdAt (biasanya handled by addUser, tapi untuk safety)
    return _db
        .collection(USERS_COLLECTION)
        .doc(user.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> addUser(UserModel user) {
    final data = user.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    return _db.collection(USERS_COLLECTION).doc(user.id).set(data);
  }

  Future<void> updateUser(UserModel user) {
    final data = user.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    // Hapus createdAt dari payload update agar tidak tertimpa
    data.remove('createdAt');

    return _db.collection(USERS_COLLECTION).doc(user.id).update(data);
  }

  Future<void> updateUserPartial(String userId, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _db.collection(USERS_COLLECTION).doc(userId).update(data);
  }

  Future<void> deleteUser(String userId) {
    return _db.collection(USERS_COLLECTION).doc(userId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // 1. Ambil List Admin (Pagination)
  Future<QuerySnapshot<Map<String, dynamic>>> getAdminsBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .where('role', isEqualTo: 'Admin') // Hanya ambil Admin
        .orderBy('nama', descending: false);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Cari User by Email (Untuk Promote)
  Future<QuerySnapshot<Map<String, dynamic>>> searchUserByEmail(String email) {
    return _db
        .collection(USERS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
  }

  // ===========================================================================
  // KAWAN SS
  // ===========================================================================

  Stream<List<KawanssModel>> getKawanssLiveStream({int limit = 50}) {
    return _db
        .collection(KAWANSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAllKawanssBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(KAWANSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getKawanssBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(KAWANSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .where(
          'uploadDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<KawanssModel>> getKawanssStream() {
    return _db
        .collection(KAWANSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<List<KawanssModel>> getKawanssInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _db
            .collection(KAWANSS_COLLECTION)
            .where('isDeleted', isEqualTo: false)
            .where(
              'uploadDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'uploadDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    return querySnapshot.docs
        .map((doc) => KawanssModel.fromFirestore(doc, null))
        .toList();
  }

  Future<DocumentReference> addKawanss(KawanssModel kawanss) {
    final data = kawanss.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    return _db.collection(KAWANSS_COLLECTION).add(data);
  }

  Future<void> updateKawanss(KawanssModel kawanss) {
    final data = kawanss.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection(KAWANSS_COLLECTION).doc(kawanss.id).update(data);
  }

  Future<void> deleteKawanss(String kawanssId) {
    return _db.collection(KAWANSS_COLLECTION).doc(kawanssId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 1. Fetch Murni Pagination (Tanpa Filter Tanggal)
  Future<QuerySnapshot<Map<String, dynamic>>> getAllKawanssCommentsBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('kawanssComments')
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getKawanssCommentsBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('kawanssComments')
        .where('isDeleted', isEqualTo: false)
        .where(
          'uploadDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 3. Stream Realtime untuk Live Monitoring Komentar (Limit 50)
  Stream<List<KawanssCommentModel>> getKawanssCommentsLiveStream({
    int limit = 50,
  }) {
    return _db
        .collection('kawanssComments')
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Stream<List<KawanssCommentModel>> getKawanssCommentsStream() {
    return _db
        .collection('kawanssComments')
        .where('isDeleted', isEqualTo: false) // Update ke isDeleted
        .orderBy('uploadDate', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => KawanssCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<void> softDeleteKawanssComment(String commentId, bool isDeleted) {
    // Fungsi ini menerima status isDeleted target (true/false)
    return _db.collection('kawanssComments').doc(commentId).update({
      'isDeleted': isDeleted, // Update ke isDeleted
      'deletedAt': isDeleted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // ===========================================================================
  // CALL HISTORY
  // ===========================================================================

  // 1. Fetch Murni Pagination (Tanpa Filter Tanggal)
  Future<QuerySnapshot<Map<String, dynamic>>> getAllCallHistoryBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('calls')
        // Kita tidak filter isDeleted karena log panggilan biasanya permanen
        // Tapi kita filter status agar yang 'dialing' (sedang menelpon) tidak masuk history
        // .where('status', whereIn: ['accepted', 'rejected', 'timeout', 'cancelled', 'completed', 'missed'])
        .orderBy('createdAt', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getCallHistoryBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('calls')
        // .where('status', whereIn: ['accepted', 'rejected', 'timeout', 'cancelled', 'completed', 'missed'])
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

    Stream<List<CallHistoryLogModel>> getCallHistoryByUser(String userId) {
    return Stream.value([]);
  }

  // ===========================================================================
  // KONTRIBUTOR / REPORTS
  // ===========================================================================

  Stream<List<KawanSSReportModel>> getKontributorsStream() {
    return _db
        .collection(KONTRIBUTOR_COLLECTION)
        .where('isDeleted', isEqualTo: false)
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
    final data = kontributor.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    return _db.collection(KONTRIBUTOR_COLLECTION).add(data);
  }

  Future<void> updateKontributor(KawanSSReportModel kontributor) {
    final data = kontributor.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db
        .collection(KONTRIBUTOR_COLLECTION)
        .doc(kontributor.id)
        .update(data);
  }

  Future<void> deleteKontributor(String kontributorId) {
    return _db.collection(KONTRIBUTOR_COLLECTION).doc(kontributorId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // BERITA (NEWS)
  // ===========================================================================

  Stream<List<BeritaModel>> getNewsStream() {
    return _db
        .collection(NEWS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
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
    final data = news.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    return _db.collection(NEWS_COLLECTION).add(data);
  }

  Future<void> updateNews(BeritaModel news) {
    final data = news.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection(NEWS_COLLECTION).doc(news.id).update(data);
  }

  Future<void> deleteNews(String newsId) {
    return _db.collection(NEWS_COLLECTION).doc(newsId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // BANNER
  // ===========================================================================

  // 1. Fetch Murni Pagination
  Future<QuerySnapshot<Map<String, dynamic>>> getAllBannerBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('bannerTop')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getBannerBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('bannerTop')
        .where('isDeleted', isEqualTo: false)
        .where(
          'tanggalPosting',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'tanggalPosting',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<BannerTopModel>> getBannersStream() {
    return _db
        .collection('bannerTop')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BannerTopModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<String> addBannerWithIdReturn(BannerTopModel banner) async {
    final data = banner.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    DocumentReference docRef = await _db.collection('bannerTop').add(data);
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Future<void> updateBanner(BannerTopModel banner) {
    final data = banner.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection('bannerTop').doc(banner.id).update(data);
  }

  Future<void> deleteBanner(String bannerId) {
    return _db.collection('bannerTop').doc(bannerId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // KATEGORI
  // ===========================================================================

  Stream<List<KategoriModel>> getKategoriStream(String collectionName) {
    return _db
        .collection(collectionName)
        .where('isDeleted', isEqualTo: false)
        .orderBy('namaKategori')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => KategoriModel.fromFirestore(doc, collectionName),
                  )
                  .toList(),
        );
  }

  Future<void> addKategori(String collectionName, KategoriModel kategori) {
    final data = kategori.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    return _db.collection(collectionName).add(data);
  }

  Future<void> deleteKategori(String collectionName, String kategoriId) {
    return _db.collection(collectionName).doc(kategoriId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // INFO SS
  // ===========================================================================

  Future<QuerySnapshot<Map<String, dynamic>>> getAllInfossBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection(INFOSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true); // Murni urutan waktu

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getInfossBatch({
    DateTime? startDate,
    DateTime? endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    // Mulai query dasar (Hanya filter isDeleted dan Order)
    Query query = _db
        .collection(INFOSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true);

    // HANYA terapkan filter tanggal jika parameternya tidak null
    if (startDate != null && endDate != null) {
      query = query
          .where(
            'uploadDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'uploadDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getInfossBatchByCategory({
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('infoss')
        .where('isDeleted', isEqualTo: false) // Filter isDeleted
        .where('kategori', isEqualTo: category)
        .where(
          'uploadDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('uploadDate', descending: true)
        .limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return await query.get();
  }

  Stream<List<InfossModel>> getInfossStream() {
    return _db
        .collection(INFOSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<List<InfossModel>> getInfossInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _db
            .collection(INFOSS_COLLECTION)
            .where('isDeleted', isEqualTo: false)
            .where(
              'uploadDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'uploadDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    return querySnapshot.docs
        .map((doc) => InfossModel.fromFirestore(doc, null))
        .toList();
  }

  Future<String> addInfossWithIdReturn(InfossModel infoss) async {
    final data = infoss.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    DocumentReference docRef = await _db
        .collection(INFOSS_COLLECTION)
        .add(data);
    await docRef.update({'id': docRef.id});
    return docRef.id; // Kembalikan ID
  }

  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    String fileName,
  ) async {
    try {
      Reference ref = _storage.ref().child(childName).child(fileName);
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = ref.putData(file, metadata);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print("Error uploading image: $e");
      throw Exception("Gagal meng-upload gambar.");
    }
  }

  Future<void> updateInfoss(InfossModel infoss) {
    final data = infoss.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection(INFOSS_COLLECTION).doc(infoss.id).update(data);
  }

  Future<void> deleteInfoss(String infossId) {
    return _db.collection(INFOSS_COLLECTION).doc(infossId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // INFO SS COMMENTS
  // ===========================================================================

  Stream<List<InfossCommentModel>> getInfossCommentsLiveStream({
    int limit = 50,
  }) {
    return _db
        .collection('infossComments')
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAllInfossCommentsBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('infossComments')
        .where('isDeleted', isEqualTo: false) // Sesuai standarisasi
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getInfossCommentsBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('infossComments')
        .where('isDeleted', isEqualTo: false)
        .where(
          'uploadDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('uploadDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('uploadDate', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<InfossCommentModel>> getInfossCommentsStream() {
    return _db
        .collection('infossComments')
        .where('isDeleted', isEqualTo: false) // Standardisasi ke isDeleted
        .orderBy('uploadDate', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<void> softDeleteInfossComment(String commentId, bool isDeleted) {
    return _db.collection('infossComments').doc(commentId).update({
      'isDeleted': isDeleted, // Standardisasi ke isDeleted
      'deletedAt': isDeleted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<InfossCommentModel>> getCommentsStreamForInfoss(String infossId) {
    return _db
        .collection('infossComments')
        .where('isDeleted', isEqualTo: false)
        .where('infossUid', isEqualTo: infossId)
        .orderBy('uploadDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossCommentModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Stream<List<InfossReplyModel>> getRepliesStreamForComment(
    String infossId,
    String commentId,
  ) {
    // Note: Replies adalah subcollection.
    // Jika replies juga perlu soft delete, pastikan model dan migrasi support.
    // Asumsi: Subcollection 'Replies' mengikuti standard jika dimigrasi.
    // Jika belum dimigrasi, filter ini mungkin perlu hati-hati.
    // Tapi untuk amannya kita pasang filter isDeleted.
    return _db
        .collection('infossComments')
        .doc(commentId)
        .collection('Replies')
        .where('isDeleted', isEqualTo: false)
        .orderBy('uploadDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InfossReplyModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<void> updateInfossComment(InfossCommentModel comment) {
    final data = comment.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db
        .collection(INFOSS_COMMENTS_COLLECTION)
        .doc(comment.id)
        .update(data);
  }

  Future<void> deleteInfossComment(String commentId) {
    return _db.collection(INFOSS_COMMENTS_COLLECTION).doc(commentId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

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
    final data = settings.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();

    return _db
        .collection('settings')
        .doc('appConfig')
        .set(data, SetOptions(merge: true));
  }

  // ===========================================================================
  // TEMA SIARAN
  // ===========================================================================

  // 1. Fetch Murni Pagination (Tanpa Filter Tanggal)
  Future<QuerySnapshot<Map<String, dynamic>>> getAllTemaSiaranBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('temaSiaran')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getTemaSiaranBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('temaSiaran')
        .where('isDeleted', isEqualTo: false)
        .where(
          'tanggalPosting',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'tanggalPosting',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<TemaSiaranModel>> getTemaSiaranStream() {
    return _db
        .collection('temaSiaran')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TemaSiaranModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<String> addTemaSiaranWithIdReturn(TemaSiaranModel tema) async {
    final data = tema.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    DocumentReference docRef = await _db.collection('temaSiaran').add(data);
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Future<void> updateTemaSiaran(TemaSiaranModel tema) {
    final data = tema.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection('temaSiaran').doc(tema.id).update(data);
  }

  Future<void> deleteTemaSiaran(String temaId) {
    return _db.collection('temaSiaran').doc(temaId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTemaSiaranAsDefault(String newDefaultId) async {
    final querySnapshot =
        await _db
            .collection('temaSiaran')
            .where('isDeleted', isEqualTo: false)
            .where('isDefault', isEqualTo: true)
            .get();

    WriteBatch batch = _db.batch();

    for (final doc in querySnapshot.docs) {
      if (doc.id != newDefaultId) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    final newDefaultRef = _db.collection('temaSiaran').doc(newDefaultId);
    batch.update(newDefaultRef, {
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ===========================================================================
  // POPUP
  // ===========================================================================

  // 1. Fetch Murni Pagination
  Future<QuerySnapshot<Map<String, dynamic>>> getAllPopUpBatch({
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('popups')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  // 2. Fetch dengan Filter Tanggal
  Future<QuerySnapshot<Map<String, dynamic>>> getPopUpBatch({
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _db
        .collection('popups')
        .where('isDeleted', isEqualTo: false)
        .where(
          'tanggalPosting',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'tanggalPosting',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy('tanggalPosting', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.limit(limit).get()
        as Future<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<List<PopUpModel>> getPopUpsStream() {
    return _db
        .collection('popups')
        .where('isDeleted', isEqualTo: false)
        .orderBy('tanggalPosting', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PopUpModel.fromFirestore(doc, null))
                  .toList(),
        );
  }

  Future<String> addPopUpWithIdReturn(PopUpModel popUp) async {
    final data = popUp.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    data['deletedAt'] = null;

    DocumentReference docRef = await _db.collection('popups').add(data);
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Future<void> updatePopUp(PopUpModel popUp) {
    final data = popUp.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('createdAt');

    return _db.collection('popups').doc(popUp.id).update(data);
  }

  Future<void> deletePopUp(String popUpId) {
    return _db.collection('popups').doc(popUpId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // ANALITIK & STATISTIK
  // ===========================================================================

  Stream<List<KawanssModel>> getPostsByUser(String userId) {
    return _db
        .collection(KAWANSS_COLLECTION)
        .where('isDeleted', isEqualTo: false)
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



  Future<List<UserModel>> getUsersInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _db
            .collection(USERS_COLLECTION)
            .where('isDeleted', isEqualTo: false)
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

    // Hitung total user yang tidak dihapus
    final totalUsers =
        (await _db
                .collection(USERS_COLLECTION)
                .where('isDeleted', isEqualTo: false)
                .count()
                .get())
            .count ??
        0;

    final allUsersSnapshot =
        await _db
            .collection(USERS_COLLECTION)
            .where('isDeleted', isEqualTo: false)
            .get();

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
        (await _db
                .collection(NEWS_COLLECTION)
                .where('isDeleted', isEqualTo: false)
                .count()
                .get())
            .count ??
        0;
    final kawanssCount =
        (await _db
                .collection(KAWANSS_COLLECTION)
                .where('isDeleted', isEqualTo: false)
                .count()
                .get())
            .count ??
        0;
    final kontributorCount =
        (await _db
                .collection(KONTRIBUTOR_COLLECTION)
                .where('isDeleted', isEqualTo: false)
                .count()
                .get())
            .count ??
        0;
    final totalPosts = newsCount + kawanssCount + kontributorCount;

    int newPosts = 0;
    final collections = [
      {'name': NEWS_COLLECTION, 'field': 'uploadDate'},
      {'name': KAWANSS_COLLECTION, 'field': 'uploadDate'},
      {'name': KONTRIBUTOR_COLLECTION, 'field': 'uploadDate'},
    ];
    for (var collectionInfo in collections) {
      final snapshot =
          await _db
              .collection(collectionInfo['name']!)
              .where('isDeleted', isEqualTo: false)
              .get();
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
            .where('isDeleted', isEqualTo: false)
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
            // Analytics biasanya log, mungkin tidak perlu isDeleted,
            // tapi jika ada fitur hapus log, tambahkan:
            // .where('isDeleted', isEqualTo: false)
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
              .where('isDeleted', isEqualTo: false)
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
    final snapshot =
        await _db
            .collection(USERS_COLLECTION)
            .where('isDeleted', isEqualTo: false)
            .get();

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
}
