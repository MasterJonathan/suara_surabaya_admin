// lib/providers/kawanss_post_provider.dart

import 'dart:async';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
import 'package:flutter/material.dart';

enum KawanssPostViewState { Idle, Busy }

class KawanssPostProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  late StreamSubscription _streamSubscription;

  List<KawanssModel> _posts = [];
  KawanssPostViewState _state = KawanssPostViewState.Busy;
  String? _errorMessage;

  List<KawanssModel> get posts => _posts;
  KawanssPostViewState get state => _state;
  String? get errorMessage => _errorMessage;

    // --- TAMBAHKAN PROPERTI BARU ---
  List<KawanssCommentModel> _comments = [];
  List<KawanssCommentModel> get comments => _comments;
  StreamSubscription? _commentsSubscription;
  // -------------------------------

  KawanssPostProvider({required FirestoreService firestoreService})
      : _firestoreService = firestoreService {
    _listenToPosts();
    _listenToComments();
  }

  void _listenToPosts() {
    // Menggunakan metode getKawanssStream yang sudah ada di FirestoreService
    _streamSubscription = _firestoreService.getKawanssStream().listen((data) {
      _posts = data;
      _setState(KawanssPostViewState.Idle);
    }, onError: (error) {
      _errorMessage = "Gagal memuat data post: $error";
      _setState(KawanssPostViewState.Idle);
    });
  }

  // Metode untuk update dan delete bisa menggunakan metode yang sama dari FirestoreService
  Future<bool> updatePost(KawanssModel post) async {
    _setState(KawanssPostViewState.Busy);
    try {
      await _firestoreService.updateKawanss(post);
      _setState(KawanssPostViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssPostViewState.Idle);
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    _setState(KawanssPostViewState.Busy);
    try {
      await _firestoreService.deleteKawanss(postId);
      _setState(KawanssPostViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(KawanssPostViewState.Idle);
      return false;
    }
  }

  void _listenToComments() {
    _commentsSubscription = _firestoreService.getKawanssCommentsStream().listen((data) {
      _comments = data;
      notifyListeners();
    }, onError: (error) {
      print("Error listening to comments: $error");
    });
  }

  Future<bool> toggleCommentStatus(String commentId, bool currentStatus) async {
    // _setState(KawanssPostViewState.Busy); // Opsional: tampilkan loading global
    try {
      // Toggle status: jika true jadi false, jika false jadi true
      await _firestoreService.softDeleteKawanssComment(commentId, !currentStatus);
      // _setState(KawanssPostViewState.Idle);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      // _setState(KawanssPostViewState.Idle);
      return false;
    }
  }

  void _setState(KawanssPostViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
     _commentsSubscription?.cancel();
    super.dispose();
  }
}