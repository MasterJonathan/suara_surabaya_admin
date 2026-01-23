

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/berita/berita_model.dart';
import 'package:flutter/material.dart';

enum BeritaViewState { Idle, Busy }

class BeritaProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<BeritaModel> _newsList = [];
  BeritaViewState _state = BeritaViewState.Busy;
  String? _errorMessage;

  List<BeritaModel> get newsList => _newsList;
  BeritaViewState get state => _state;
  String? get errorMessage => _errorMessage;

  BeritaProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToNews();
  }

  void _listenToNews() {
    
    _streamSubscription = _firestoreService.getNewsStream().listen((data) {
      _newsList = data;
      _setState(BeritaViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data berita: $error";
      _setState(BeritaViewState.Idle);
    });
  }

  Future<bool> addNews(BeritaModel news) async {
    _setState(BeritaViewState.Busy);
    try {
      
      await _firestoreService.addNews(news);
      _setState(BeritaViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BeritaViewState.Idle);
      return false;
    }
  }

  Future<bool> updateNews(BeritaModel news) async {
    _setState(BeritaViewState.Busy);
    try {
      
      await _firestoreService.updateNews(news);
      _setState(BeritaViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BeritaViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteNews(String newsId) async {
    _setState(BeritaViewState.Busy);
    try {
      
      await _firestoreService.deleteNews(newsId);
      _setState(BeritaViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BeritaViewState.Idle);
      return false;
    }
  }

  void _setState(BeritaViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}