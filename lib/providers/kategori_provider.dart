// lib/providers/kategori_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/core/utils/constants.dart';
import 'package:suara_surabaya_admin/models/kategori_model.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Tambahkan package rxdart

enum KategoriViewState { Idle, Busy }

class KategoriProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  late StreamSubscription _combinedSubscription;

  // Hanya satu list untuk semua kategori
  List<KategoriModel> _allKategori = [];
  KategoriViewState _state = KategoriViewState.Busy;
  String? _errorMessage;

  List<KategoriModel> get allKategori => _allKategori;
  KategoriViewState get state => _state;
  String? get errorMessage => _errorMessage;

  KategoriProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToAllKategori();
  }

  void _listenToAllKategori() {
    _setState(KategoriViewState.Busy);

    // Ambil stream dari setiap koleksi
    final stream1 = _firestoreService.getKategoriStream(KATEGORI_INFOSS_COLLECTION);
    final stream2 = _firestoreService.getKategoriStream(KATEGORI_KAWANSS_COLLECTION);
    final stream3 = _firestoreService.getKategoriStream(KATEGORI_NEWS_COLLECTION);

    // Gabungkan ketiga stream menjadi satu menggunakan rxdart
    _combinedSubscription = CombineLatestStream.list([stream1, stream2, stream3])
        .listen((listOfLists) {
          // listOfLists adalah List<List<KategoriModel>>
          // Gabungkan semua list menjadi satu list tunggal
          _allKategori = listOfLists.expand((list) => list).toList();
          // Urutkan hasil gabungan berdasarkan nama
          _allKategori.sort((a, b) => a.namaKategori.compareTo(b.namaKategori));
          _setState(KategoriViewState.Idle);
        }, onError: _handleError);
  }

  void _handleError(error) {
    _errorMessage = "Gagal memuat data kategori: $error";
    _setState(KategoriViewState.Idle);
  }

  Future<bool> addKategori(String collectionName, String namaKategori) async {
    _setState(KategoriViewState.Busy);
    try {
      // 'jenis' tidak perlu disimpan di model saat membuat, karena sudah ditentukan oleh collectionName
      final newKategori = KategoriModel(id: '', namaKategori: namaKategori, jenis: collectionName);
      await _firestoreService.addKategori(collectionName, newKategori);
      _setState(KategoriViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KategoriViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteKategori(String collectionName, String kategoriId) async {
    _setState(KategoriViewState.Busy);
    try {
      await _firestoreService.deleteKategori(collectionName, kategoriId);
      _setState(KategoriViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KategoriViewState.Idle);
      return false;
    }
  }

  void _setState(KategoriViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _combinedSubscription.cancel();
    super.dispose();
  }
}