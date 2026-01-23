

// import 'dart:async';
// import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
// import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart'; 
// import 'package:flutter/material.dart';

// enum ChatViewState { Idle, Busy }

// class ChatProvider extends ChangeNotifier {
//   final FirestoreService _firestoreService;
//   late StreamSubscription _infossCommentsSubscription;
  

//   List<InfossCommentModel> _infossComments = [];
//   ChatViewState _state = ChatViewState.Busy;
//   String? _errorMessage;

//   List<InfossCommentModel> get infossComments => _infossComments;
//   ChatViewState get state => _state;
//   String? get errorMessage => _errorMessage;

//   ChatProvider({required FirestoreService firestoreService})
//       : _firestoreService = firestoreService {
//     _listenToInfossComments();
    
//   }

//   void _listenToInfossComments() {
    
//     _infossCommentsSubscription = _firestoreService.getCommentsStreamForInfoss().listen((data) {
//       _infossComments = data;
//       _setState(ChatViewState.Idle);
//     }, onError: (error) {
//       _errorMessage = "Gagal memuat komentar infoss: $error";
//       _setState(ChatViewState.Idle);
//     });
//   }

  
//   Future<bool> updateComment(InfossCommentModel comment) async {
//     _setState(ChatViewState.Busy);
//     try {
      
//       await _firestoreService.updateInfossComment(comment);
//       _setState(ChatViewState.Idle);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       _setState(ChatViewState.Idle);
//       return false;
//     }
//   }

//   Future<bool> deleteComment(String commentId) async {
//     _setState(ChatViewState.Busy);
//     try {
      
//       await _firestoreService.deleteInfossComment(commentId);
//       _setState(ChatViewState.Idle);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       _setState(ChatViewState.Idle);
//       return false;
//     }
//   }

//   void _setState(ChatViewState newState) {
//     _state = newState;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _infossCommentsSubscription.cancel();
    
//     super.dispose();
//   }
// }