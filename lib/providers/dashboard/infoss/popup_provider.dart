// lib/providers/popup_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/popup_model.dart';
import 'package:flutter/material.dart';

enum PopUpViewState { Idle, Busy }

class PopUpProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<PopUpModel> _popups = [];
  PopUpViewState _state = PopUpViewState.Busy;
  String? _errorMessage;

  List<PopUpModel> get popups => _popups;
  PopUpViewState get state => _state;
  String? get errorMessage => _errorMessage;

  PopUpProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToPopUps();
  }

  void _listenToPopUps() {
    _streamSubscription = _firestoreService.getPopUpsStream().listen((data) {
      _popups = data;
      _setState(PopUpViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data Pop Up: $error";
      _setState(PopUpViewState.Idle);
    });
  }

  Future<bool> addPopUp(PopUpModel popUp) async {
    _setState(PopUpViewState.Busy);
    try {
      await _firestoreService.addPopUp(popUp);
      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  Future<bool> updatePopUp(PopUpModel popUp) async {
    _setState(PopUpViewState.Busy);
    try {
      await _firestoreService.updatePopUp(popUp);
      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  Future<bool> deletePopUp(String popUpId) async {
    _setState(PopUpViewState.Busy);
    try {
      await _firestoreService.deletePopUp(popUpId);
      _setState(PopUpViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PopUpViewState.Idle);
      return false;
    }
  }

  void _setState(PopUpViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}