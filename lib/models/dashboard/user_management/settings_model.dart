

import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsModel {
  final String audioStreamingUrl;
  final String visualRadioUrl;
  final String termsAndConditions;
  final bool isChatActive;

  SettingsModel({
    required this.audioStreamingUrl,
    required this.visualRadioUrl,
    required this.termsAndConditions,
    required this.isChatActive,
  });

  
  factory SettingsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return SettingsModel(
      audioStreamingUrl: data?['audioStreamingUrl'] ?? '',
      visualRadioUrl: data?['visualRadioUrl'] ?? '',
      termsAndConditions: data?['termsAndConditions'] ?? '',
      isChatActive: data?['isChatActive'] ?? false,
    );
  }

  
  Map<String, dynamic> toFirestore() {
    return {
      'audioStreamingUrl': audioStreamingUrl,
      'visualRadioUrl': visualRadioUrl,
      'termsAndConditions': termsAndConditions,
      'isChatActive': isChatActive,
    };
  }
}