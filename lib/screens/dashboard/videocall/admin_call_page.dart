// lib/screens/dashboard/admin_call_page.dart

import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/videocall/video_call_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminCallPage extends StatefulWidget {
  const AdminCallPage({super.key});

  @override
  State<AdminCallPage> createState() => _AdminCallPageState();
}

class _AdminCallPageState extends State<AdminCallPage> {
  final Set<String> _processingCallIds = {};

  // BELUM ENABLE
  Future<void> _checkUserRegistration(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      print("Nomor telepon tidak ditemukan, API tidak dipanggil.");
      return;
    }

    final String apiUrl = dotenv.env['PHONE_API'] ?? '';
    
    // --- PERBAIKAN: Ambil secret key dari .env ---
    final String secretKey = dotenv.env['SS_LOGCALL_SECRET_KEY'] ?? '';
    if (secretKey.isEmpty) {
      print("Error: ABSENSI_SECRET_KEY tidak ditemukan di file .env");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi error: Secret key tidak ditemukan.')),
        );
      }
      return;
    }
    // ------------------------------------------------

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'secret_key': secretKey,
          'phone': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        SnackBar snackBar;
        if (responseBody == '1') {
          snackBar = const SnackBar(
            content: Text('Status: Pengguna sudah terdaftar.'),
            backgroundColor: Colors.green,
          );
        } else if (responseBody == '0') {
          snackBar = const SnackBar(
            content: Text('Status: Pengguna belum terdaftar.'),
            backgroundColor: Colors.orange,
          );
        } else {
          snackBar = SnackBar(content: Text('Respons server tidak dikenal: $responseBody'));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghubungi server absensi: Status ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan saat cek absensi: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Panggilan Masuk', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const Divider(),
          Expanded(
            flex: 1, 
            child: callProvider.queuedCalls.isEmpty
                ? const Center(child: Text('Tidak ada panggilan dalam antrian.'))
                : _buildQueuedCallsList(context, callProvider.queuedCalls),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text('Panggilan Aktif', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const Divider(),
          Expanded(
            flex: 1,
            child: callProvider.activeCalls.isEmpty
                ? const Center(child: Text('Tidak ada panggilan yang sedang aktif.'))
                : _buildActiveCallsList(context, callProvider.activeCalls),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedCallsList(BuildContext context, List<QueryDocumentSnapshot> calls) {
    final callProvider = context.read<CallProvider>();
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final callDoc = calls[index];
        final callData = callDoc.data() as Map<String, dynamic>;
        final callId = callDoc.id;
        final isProcessing = _processingCallIds.contains(callId);

        final String username = callData['username'] ?? 'User';
        final String photoURL = callData['photoURL'] ?? '';
        final bool isVideoCall = callData['isVideoCall'] ?? false;
        final DateTime createdAt = (callData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(username),
          subtitle: Text('Memanggil ${timeago.format(createdAt, locale: 'id')}'),
          trailing: isProcessing
              ? const CircularProgressIndicator()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(isVideoCall ? Icons.videocam : Icons.phone, size: 16),
                      label: const Text('Jawab'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () async {
                        setState(() => _processingCallIds.add(callId));
                        try {
                          // PANGGIL API Belum ENABLE
                          final String userId = callData['userId'];
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                          if (userDoc.exists) {
                            // NOT ENABLE
                            // final String? phoneNumber = userDoc.data()?['nomorHp'];
                            // await _checkUserRegistration(phoneNumber);
                          }


                          final callDetails = await callProvider.answerAndClaimCall(callDoc);
                          if (callDetails != null && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VideoCallPage(
                                  channelName: callDetails['channelName'],
                                  token: callDetails['token'],
                                  uid: callDetails['uid'],
                                  callId: callDoc.id,
                                  originalUserId: callDetails['originalUserId'],
                                  originalCallerUid: callDetails['originalCallerUid'],
                                  isVideoCall: isVideoCall,
                                  username: username, // <-- PERBAIKAN: Kirim nama penelpon
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _processingCallIds.remove(callId));
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.error,
                      onPressed: () => callProvider.rejectCall(callId),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildActiveCallsList(BuildContext context, List<QueryDocumentSnapshot> calls) {
    final callProvider = context.read<CallProvider>();
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final callDoc = calls[index];
        final callData = callDoc.data() as Map<String, dynamic>;
        final String username = callData['username'] ?? 'User';
        final String photoURL = callData['photoURL'] ?? '';
        final bool isVideoCall = callData['isVideoCall'] ?? false;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.success.withValues(alpha: 0.2),
            backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
            child: photoURL.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(username),
          subtitle: const Text('Sedang dalam panggilan...'),
          trailing: ElevatedButton.icon(
            icon: Icon(isVideoCall ? Icons.videocam_outlined : Icons.phone_in_talk_outlined, size: 16),
            label: const Text('Gabung'),
            onPressed: () {
              final callDetails = callProvider.joinExistingCall(callDoc);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoCallPage(
                    channelName: callDetails['channelName'],
                    token: callDetails['token'],
                    uid: callDetails['uid'],
                    callId: callDoc.id,
                    originalUserId: callDetails['originalUserId'],
                    originalCallerUid: callDetails['originalCallerUid'],
                    isVideoCall: isVideoCall,
                    username: username, // <-- PERBAIKAN: Kirim nama penelpon
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}