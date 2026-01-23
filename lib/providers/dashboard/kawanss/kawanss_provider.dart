import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:flutter/material.dart';

enum KawanssViewState { Idle, Busy }

class KawanssProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<KawanssModel> _kawanssList = [];
  KawanssViewState _state = KawanssViewState.Busy;
  String? _errorMessage;

  List<KawanssModel> get kawanssList => _kawanssList;
  KawanssViewState get state => _state;
  String? get errorMessage => _errorMessage;

  KawanssProvider({required FirestoreService firestoreService})
    : _firestoreService = firestoreService {
    _listenToKawanss();
  }

  void _listenToKawanss() {
    _streamSubscription = _firestoreService.getKawanssStream().listen(
      (data) {
        _kawanssList = data;
        if (hasListeners) {
          _setState(KawanssViewState.Idle);
        }
      },
      onError: (error) {
        _errorMessage = "Gagal memuat data Kawan SS: $error";
        if (hasListeners) {
          _setState(KawanssViewState.Idle);
        }
      },
    );
  }

  Future<bool> addKawanss(KawanssModel kawanss) async {
    _setState(KawanssViewState.Busy);
    try {
      await _firestoreService.addKawanss(kawanss);
      _setState(KawanssViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssViewState.Idle);
      return false;
    }
  }

  Future<bool> updateKawanss(KawanssModel kawanss) async {
    _setState(KawanssViewState.Busy);
    try {
      await _firestoreService.updateKawanss(kawanss);
      _setState(KawanssViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssViewState.Idle);
      return false;
    }
  }

  Future<bool> deleteKawanss(String kawanssId) async {
    _setState(KawanssViewState.Busy);
    try {
      await _firestoreService.deleteKawanss(kawanssId);
      _setState(KawanssViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssViewState.Idle);
      return false;
    }
  }

  void _setState(KawanssViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
