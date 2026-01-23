

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String kontributorName;
  final String chatMessage;
  final bool status;
  final DateTime tanggalPosting;

  ChatMessageModel({
    required this.id,
    required this.kontributorName,
    required this.chatMessage,
    required this.status,
    required this.tanggalPosting,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return ChatMessageModel(
      id: snapshot.id,
      kontributorName: data?['kontributorName'] ?? '',
      chatMessage: data?['chatMessage'] ?? '',
      status: data?['status'] ?? false,
      tanggalPosting: (data?['tanggalPosting'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kontributorName': kontributorName,
      'chatMessage': chatMessage,
      'status': status,
      'tanggalPosting': Timestamp.fromDate(tanggalPosting),
    };
  }
}