// lib/screens/dashboard/call_simulator_page.dart

import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call/call_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/call/user_waiting_page.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CallSimulatorPage extends StatefulWidget {
  const CallSimulatorPage({super.key});

  @override
  State<CallSimulatorPage> createState() => _CallSimulatorPageState();
}

class _CallSimulatorPageState extends State<CallSimulatorPage> {
  bool _isLoading = false;

  Future<void> _startCall(bool isVideoCall) async {
    final callProvider = context.read<CallProvider>();
    final authProvider = context.read<AuthenticationProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    setState(() => _isLoading = true);

    // Hanya membuat dokumen di Firestore, tidak langsung join
    final callId = await callProvider.initiateCall(
      currentUser: currentUser,
      isVideoCall: isVideoCall,
    );

    if (callId != null && mounted) {
      // Navigasi ke halaman tunggu
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserWaitingPage(callId: callId),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat panggilan.')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    final currentUser = authProvider.user;

    return CustomCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Halaman Simulasi Panggilan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (currentUser == null)
              const Text("Silakan login terlebih dahulu.")
            else ...[
              Text("Anda akan menelepon sebagai: ${currentUser.nama}"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text("Panggilan Suara"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _isLoading ? null : () => _startCall(false),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text("Panggilan Video"),
                    onPressed: _isLoading ? null : () => _startCall(true),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}