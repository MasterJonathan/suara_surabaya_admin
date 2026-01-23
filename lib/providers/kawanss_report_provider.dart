

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/kawanss_report_model.dart';
import 'package:flutter/material.dart';

enum KawanSSViewState { Idle, Busy }

class KawanSSReportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<KawanSSReportModel> _kontributors = [];
  KawanSSViewState _state = KawanSSViewState.Busy;
  String? _errorMessage;

  List<KawanSSReportModel> get kontributors => _kontributors;
  KawanSSViewState get state => _state;
  String? get errorMessage => _errorMessage;

  KawanSSReportProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToKontributors();
  }

  void _listenToKontributors() {
    _streamSubscription = _firestoreService.getKontributorsStream().listen((data) {
      _kontributors = data;
      _setState(KawanSSViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data kontributor: $error";
      _setState(KawanSSViewState.Idle);
    });
  }

  Future<bool> addKontributor(KawanSSReportModel kontributor) async {
    _setState(KawanSSViewState.Busy);
    try {
      await _firestoreService.addKontributor(kontributor);
      _setState(KawanSSViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanSSViewState.Idle);
      return false;
    }
  }

  Future<bool> updateKontributor(KawanSSReportModel kontributor) async {
    _setState(KawanSSViewState.Busy);
    try {
      await _firestoreService.updateKontributor(kontributor);
      _setState(KawanSSViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanSSViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteKontributor(String kontributorId) async {
    _setState(KawanSSViewState.Busy);
    try {
      await _firestoreService.deleteKontributor(kontributorId);
      _setState(KawanSSViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanSSViewState.Idle);
      return false;
    }
  }

  void _setState(KawanSSViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}