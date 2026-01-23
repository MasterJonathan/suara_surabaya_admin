// lib/screens/dashboard/video_call_page.dart

import 'dart:async';
import 'package:suara_surabaya_admin/providers/dashboard/call_provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final String token;
  final int uid;
  final String callId;
  final String originalUserId;
  final int originalCallerUid;
  final bool isVideoCall;
  final String username; // <-- Parameter baru

  const VideoCallPage({
    Key? key,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.callId,
    required this.originalUserId,
    required this.originalCallerUid,
    this.isVideoCall = true,
    required this.username, // <-- Parameter baru
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final RtcEngine _engine;
  late final CallProvider _callProvider;

  bool _localUserJoined = false;
  final Set<int> _remoteUids = {};
  String? _error;

  List<VideoDeviceInfo> _cameraDevices = [];
  String? _selectedCameraId;

  int? _mainRemoteUid;
  bool get _isCaller => widget.uid == widget.originalCallerUid;

  // --- PERBAIKAN 1: State untuk visibilitas kontrol ---
  bool _areControlsVisible = true;
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _callProvider = context.read<CallProvider>();

    if (!_isCaller) {
      _mainRemoteUid = widget.originalCallerUid;
    }

    initAgora();
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }

  Future<void> _disposeEngine() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(appId: dotenv.env['AGORA_APP_ID']!),
      );

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess:
              (c, e) => setState(() => _localUserJoined = true),
          onUserJoined: (c, remoteUid, e) {
            setState(() {
              _remoteUids.add(remoteUid);
              if (_isCaller && _mainRemoteUid == null) {
                _mainRemoteUid = remoteUid;
              }
            });
          },
          onUserOffline: (c, remoteUid, r) {
            setState(() {
              _remoteUids.remove(remoteUid);
              if (remoteUid == _mainRemoteUid) {
                if (_isCaller) {
                  _mainRemoteUid = _remoteUids.firstOrNull;
                } else if (remoteUid == widget.originalCallerUid) {
                  if (mounted) Navigator.of(context).pop();
                }
              }
            });
          },
          onError:
              (err, msg) => setState(() => _error = 'Error: $err, Pesan: $msg'),
        ),
      );

      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      if (_isCaller) {
        if (widget.isVideoCall) {
          await _engine.enableVideo();
          await Future.delayed(
            const Duration(milliseconds: 100),
          ); // Beri jeda singkat
          await _engine.startPreview();
        } else {
          await _engine.enableAudio();
        }
      } else {
        // Admin
        await _engine
            .enableVideo(); // Selalu aktifkan video untuk akses device manager
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Beri jeda singkat
        if (widget.isVideoCall) {
          await _engine
              .startPreview(); // Tapi hanya preview jika ini video call
        }
        await _getCameraDevices(); // Selalu ambil device untuk admin
      }

      await _joinChannel();
    } catch (e) {
      setState(() => _error = "Gagal inisialisasi: ${e.toString()}");
    }
  }

  Future<void> _getCameraDevices() async {
    try {
      final devices =
          await _engine.getVideoDeviceManager().enumerateVideoDevices();
      if (mounted) {
        setState(() {
          _cameraDevices = devices;
          if (_cameraDevices.isNotEmpty) {
            _selectedCameraId = _cameraDevices.first.deviceId;
          }
        });
      }
    } catch (e) {
      print("Gagal mendapatkan daftar kamera: $e");
    }
  }

  void _switchCamera(String? newDeviceId) {
    if (newDeviceId != null && newDeviceId != _selectedCameraId) {
      _engine.getVideoDeviceManager().setDevice(newDeviceId);
      setState(() => _selectedCameraId = newDeviceId);
    }
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: ChannelMediaOptions(
        publishCameraTrack: widget.isVideoCall,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> _hangUp() async {
    if (_isCaller) {
      await _callProvider.endCall(widget.callId);
    } else {
      final otherAdmins = _remoteUids.where(
        (uid) => uid != widget.originalCallerUid,
      );
      if (otherAdmins.isEmpty) {
        await _callProvider.endCall(widget.callId);
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      extendBodyBehindAppBar:
          true, // Biarkan body berada di belakang AppBar transparan
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _areControlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AppBar(
            title: Text(
              'Panggilan dengan: ${widget.username}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _areControlsVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                onPressed:
                    () => setState(
                      () => _areControlsVisible = !_areControlsVisible,
                    ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _areControlsVisible = !_areControlsVisible),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('calls')
                  .doc(widget.callId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final callData = snapshot.data!.data() as Map<String, dynamic>;
              final status = callData['status'];
              if (status == 'completed' ||
                  status == 'rejected' ||
                  status == 'cancelled') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                });
                return const Center(
                  child: Text(
                    "Panggilan telah berakhir.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
            }
            return _buildCallUI();
          },
        ),
      ),
    );
  }

  Widget _buildCallUI() {
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    if (!_localUserJoined)
      return const Center(child: CircularProgressIndicator());

    // --- PERBAIKAN UTAMA: Bungkus Stack dengan SafeArea ---
    // Ini akan memastikan konten di dalamnya tidak tumpang tindih dengan status bar atau AppBar
    return SafeArea(
      child: Stack(
        children: [
          _buildMainRemoteView(),
          _buildSecondaryRemoteViews(),
          _buildLocalVideo(),
          AnimatedOpacity(
            opacity: _areControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildControls(),
          ),
        ],
      ),
    );
    // --------------------------------------------------
  }

  Widget _buildMainRemoteView() {
    if (_mainRemoteUid != null && _remoteUids.contains(_mainRemoteUid)) {
      if (widget.isVideoCall) {
        return Center(
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: _mainRemoteUid!),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          ),
        );
      } else {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 100, color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Dalam Panggilan Suara",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        );
      }
    } else {
      return Center(
        child: Text(
          "Menunggu ${_isCaller ? 'admin' : 'penelpon'} bergabung...",
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildSecondaryRemoteViews() {
    if (!widget.isVideoCall) return const SizedBox.shrink();
    final secondaryUids =
        _remoteUids.where((uid) => uid != _mainRemoteUid).toList();
    if (secondaryUids.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        height: 120,
        padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: secondaryUids.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                width: 90,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: secondaryUids[index]),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    if (!widget.isVideoCall) return const SizedBox.shrink();
    return Positioned(
      top: 16.0,
      left: 16.0,
      child: SizedBox(
        width: 120,
        height: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Colors.black.withValues(alpha: 0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- PERBAIKAN 2: Kembalikan dropdown kamera ---
            if (!_isCaller && _cameraDevices.length > 1) _buildCameraSelector(),
            if (!_isCaller && _cameraDevices.length > 1)
              const SizedBox(height: 12),
            // -------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _hangUp,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSelector() {
    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCameraId,
          isExpanded: true,
          dropdownColor: Colors.grey[850],
          focusColor: Colors.transparent,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items:
              _cameraDevices.map((device) {
                return DropdownMenuItem(
                  value: device.deviceId,
                  child: Text(
                    device.deviceName ?? 'Kamera Tidak Dikenal',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: _switchCamera,
        ),
      ),
    );
  }
}
