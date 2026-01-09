import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class VideoCall extends StatefulWidget {
  final String channelId;
  final int userId;
  final String astrologerName; // Add astrologer name parameter
  final String token; // Add token parameter

  const VideoCall({
    Key? key,
    required this.channelId,
    required this.userId,
    required this.astrologerName,
    required this.token,
  }) : super(key: key);

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  static const String appId = '8becabe35711453abd90b3139d63f824';
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  bool isVideoDisabled = false;
  bool isFrontCamera = true;
  late RtcEngine _engine;
  bool _isPermissionsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _rejectConsultation() async {
    try {
      debugPrint(
          'Rejecting consultation with ${widget.astrologerName} (Channel: ${widget.channelId})');
      final response = await http.get(
        Uri.parse(
            'https://astroboon.com/reject_consultation?id=${widget.channelId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Consultation rejected successfully');
        _leaveCall();
      } else {
        debugPrint('Failed to reject consultation: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to reject consultation')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error rejecting consultation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _initializeEverything() async {
    await _requestPermissions();
    if (_isPermissionsGranted) {
      await _initAgora();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    _registerEventHandlers();
    await _engine.enableVideo();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.startPreview();
    await _joinChannel();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    setState(() {
      _isPermissionsGranted = cameraStatus.isGranted && micStatus.isGranted;
    });

    if (!_isPermissionsGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Camera and microphone permissions are required')),
      );
    }
  }

  void _registerEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Joined channel: ${connection.channelId}');
          setState(() => isJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user joined: $remoteUid');
          setState(() => this.remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('Remote user left: $remoteUid');
          setState(() => this.remoteUid = null);
          _leaveCall();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Error: $err - $msg');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $msg')),
            );
          }
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: '', // Add your Agora token if needed
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: !isVideoDisabled,
        publishMicrophoneTrack: !isMuted,
      ),
    );
  }

  Future<void> _leaveCall() async {
    await _engine.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleMute() async {
    setState(() => isMuted = !isMuted);
    await _engine.muteLocalAudioStream(isMuted);
  }

  Future<void> _toggleVideo() async {
    setState(() => isVideoDisabled = !isVideoDisabled);
    await _engine.muteLocalVideoStream(isVideoDisabled);
    await _engine.enableLocalVideo(!isVideoDisabled);
  }

  Future<void> _switchCamera() async {
    setState(() => isFrontCamera = !isFrontCamera);
    await _engine.switchCamera();
  }

  Widget _renderLocalPreview() {
    if (isVideoDisabled) {
      return Container(
        color: Colors.black,
        child:
            const Center(child: Icon(Icons.videocam_off, color: Colors.white)),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _renderRemoteVideo() {
    if (remoteUid == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Colors.white),
            SizedBox(height: 16),
            Text('Waiting for participant to join...',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: widget.channelId),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, VoidCallback onPressed, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.3),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing video call...'),
            ],
          ),
        ),
      );
    }

    if (!_isPermissionsGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permissions Required')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera and microphone permissions are required'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _renderRemoteVideo(),
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _renderLocalPreview(),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Astrologer: ${widget.astrologerName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  isMuted ? Icons.mic_off : Icons.mic,
                  _toggleMute,
                  Colors.blue,
                ),
                _buildActionButton(
                  Icons.call_end,
                  _rejectConsultation, // Changed from _leaveCall to _rejectConsultation
                  Colors.red,
                ),
                _buildActionButton(
                  isVideoDisabled ? Icons.videocam_off : Icons.videocam,
                  _toggleVideo,
                  Colors.blue,
                ),
                _buildActionButton(
                  Icons.cameraswitch,
                  _switchCamera,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
