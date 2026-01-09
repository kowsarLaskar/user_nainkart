import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;

class AudioCall extends StatefulWidget {
  final String channelId;
  final int userId;
  final String astrologerName; // Add astrologer name parameter
  final String token; // Add token parameter

  AudioCall({
    required this.channelId,
    required this.userId,
    required this.astrologerName,
    required this.token,
  });

  @override
  _AudioCallState createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {
  static const String appId = '8becabe35711453abd90b3139d63f824';
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  late RtcEngine _engine;
  bool _isPermissionsGranted = false;
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing AudioCall screen...");
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    debugPrint("Starting initialization process...");
    await _requestPermissions();

    if (_isPermissionsGranted) {
      debugPrint("Permissions granted. Initializing Agora...");
      await _initAgora();
    } else {
      debugPrint("Permissions not granted.");
    }

    setState(() => _isLoading = false);
    debugPrint("Initialization complete.");
  }

  Future<void> _initAgora() async {
    debugPrint("Initializing Agora engine...");
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    _registerEventHandlers();
    await _engine.enableAudio();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _joinChannel();
    debugPrint("Agora initialized.");
  }

  Future<void> _requestPermissions() async {
    debugPrint("Requesting microphone permission...");
    final micStatus = await Permission.microphone.request();

    setState(() {
      _isPermissionsGranted = micStatus.isGranted;
    });

    if (!_isPermissionsGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
    } else {
      debugPrint("Microphone permission granted.");
    }
  }

  void _registerEventHandlers() {
    debugPrint("Registering Agora event handlers...");
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
    debugPrint("Joining Agora channel...");
    await _engine.joinChannel(
      token: '', // Add your Agora token if needed
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: !isMuted,
      ),
    );
    debugPrint("Joined channel ${widget.channelId}");
  }

  Future<void> _leaveCall() async {
    debugPrint("Leaving call...");
    await _engine.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleMute() async {
    debugPrint("Toggling mute...");
    setState(() => isMuted = !isMuted);
    await _engine.muteLocalAudioStream(isMuted);
  }

  Widget _renderRemoteAudio() {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.headset, size: 100, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            'In call with ${widget.astrologerName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    debugPrint("Disposing AudioCall screen...");
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      debugPrint("Loading screen active...");
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing audio call...'),
            ],
          ),
        ),
      );
    }

    if (!_isPermissionsGranted) {
      debugPrint("Permissions not granted, showing permission screen...");
      return Scaffold(
        appBar: AppBar(title: const Text('Permissions Required')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Microphone permission is required'),
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
          _renderRemoteAudio(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
