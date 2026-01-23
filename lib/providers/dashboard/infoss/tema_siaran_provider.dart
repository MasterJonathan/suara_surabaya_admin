// lib/providers/tema_siaran_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/tema_siaran_model.dart';
import 'package:flutter/material.dart';

enum TemaSiaranViewState { Idle, Busy }

class TemaSiaranProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<TemaSiaranModel> _temas = [];
  TemaSiaranViewState _state = TemaSiaranViewState.Busy;
  String? _errorMessage;

  List<TemaSiaranModel> get temas => _temas;
  TemaSiaranViewState get state => _state;
  String? get errorMessage => _errorMessage;

  TemaSiaranProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToTemas();
  }

  void _listenToTemas() {
    _streamSubscription = _firestoreService.getTemaSiaranStream().listen((data) {
      _temas = data;
      _setState(TemaSiaranViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data Tema Siaran: $error";
      _setState(TemaSiaranViewState.Idle);
    });
  }

  Future<bool> addTemaSiaran(TemaSiaranModel tema) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      await _firestoreService.addTemaSiaran(tema);
      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> updateTemaSiaran(TemaSiaranModel tema) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      await _firestoreService.updateTemaSiaran(tema);
      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteTemaSiaran(String temaId) async {
    _setState(TemaSiaranViewState.Busy);
    try {
      await _firestoreService.deleteTemaSiaran(temaId);
      _setState(TemaSiaranViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(TemaSiaranViewState.Idle);
      return false;
    }
  }

  Future<bool> setAsDefault(String temaId) async {
    // Tidak perlu set state busy agar UI tidak berkedip
    try {
      await _firestoreService.setTemaSiaranAsDefault(temaId);
      // Data akan otomatis diperbarui oleh stream listener, tidak perlu notifyListeners()
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengatur default: ${e.toString()}";
      notifyListeners(); // Beri tahu UI jika ada error
      return false;
    }
  }

  void _setState(TemaSiaranViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}