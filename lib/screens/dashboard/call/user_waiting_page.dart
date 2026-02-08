// lib/screens/dashboard/user_waiting_page.dart

import 'package:suara_surabaya_admin/screens/dashboard/call/call_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call/call_provider.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';

class UserWaitingPage extends StatelessWidget {
  final String callId;

  const UserWaitingPage({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menunggu Panggilan"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('calls')
                .doc(callId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Panggilan dibatalkan atau error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Panggilan tidak ditemukan.")),
                );
              }
            });
            return const Center(child: Text("Panggilan tidak ditemukan."));
          }

          final callData = snapshot.data!.data() as Map<String, dynamic>;
          final status = callData['status'];

          // Navigasi berdasarkan status panggilan
          if (status == 'accepted') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => VideoCallPage(
                        channelName: callData['channelName'],
                        username: callData['username'],
                        token:
                            callData['callerToken'], // Token khusus untuk user
                        uid: callData['callerUid'],
                        callId: callId,
                        originalUserId: callData['userId'],
                        originalCallerUid: callData['callerUid'],
                      ),
                ),
              );
            });
            // Tampilkan loading sementara navigasi
            return const Center(child: CircularProgressIndicator());
          }

          if (status == 'rejected' || status == 'completed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      status == 'rejected'
                          ? "Panggilan ditolak."
                          : "Panggilan Selesai.",
                    ),
                  ),
                );
              }
            });
            return Center(
              child: Text(
                "Panggilan ${status == 'rejected' ? 'ditolak' : 'selesai'}.",
              ),
            );
          }

          // Status 'queued' (atau 'ringing' dari kode lama)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Menghubungkan ke admin...',
                  style: TextStyle(fontSize: 18, color: AppColors.primary),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),

                  onPressed: () {
                    // Batalkan panggilan
                    context.read<CallProvider>().cancelCall(callId);
                    Navigator.pop(context);
                  },
                  child: const Text('Batalkan Panggilan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
