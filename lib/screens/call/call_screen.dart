import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import '../../theme/app_theme.dart';

/// หน้าจอ Voice / Video Call จริง ผ่าน Agora RTC
/// ทั้งสองฝั่ง (นักเรียน/ครู) เข้า channelName เดียวกันจะเจอกันอัตโนมัติ
class CallScreen extends StatefulWidget {
  final String channelName;
  final bool isVideo;
  final int? myUid; // ใช้ hashCode ของ uid string ถ้าไม่ระบุ
  final String remoteName;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.isVideo,
    this.myUid,
    this.remoteName = '',
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  int? _remoteUid;
  bool _joined = false;
  bool _muted = false;
  bool _cameraOff = false;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _callService.requestPermissions(video: widget.isVideo);
      final engine = await _callService.initEngine();

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _joined = true;
            _connecting = false;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUid = null);
        },
        onError: (err, msg) {
          setState(() => _error = 'เชื่อมต่อล้มเหลว: $msg');
        },
      ));

      final uid = widget.myUid ?? DateTime.now().millisecondsSinceEpoch % 100000;
      await _callService.joinChannel(
        channelName: widget.channelName,
        uid: uid,
        video: widget.isVideo,
      );
    } catch (e) {
      setState(() {
        _error = 'ไม่สามารถเริ่มการโทรได้: กรุณาตั้งค่า Agora App ID ก่อน (ดู README.md)\n$e';
        _connecting = false;
      });
    }
  }

  @override
  void dispose() {
    _callService.leaveChannel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.isVideo && _remoteUid != null)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _callService.engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(radius: 50, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 50, color: Colors.white)),
                    const SizedBox(height: 16),
                    Text(widget.remoteName, style: const TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                      _error != null
                          ? _error!
                          : (_connecting ? 'กำลังเชื่อมต่อ...' : 'รอผู้เข้าร่วมอีกฝั่ง...'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            if (widget.isVideo && _joined)
              Positioned(
                top: 16,
                right: 16,
                width: 100,
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _cameraOff
                      ? Container(color: Colors.grey.shade800)
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _callService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                ),
              ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CallBtn(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    onTap: () {
                      setState(() => _muted = !_muted);
                      _callService.engine?.muteLocalAudioStream(_muted);
                    },
                  ),
                  const SizedBox(width: 20),
                  _CallBtn(
                    icon: Icons.call_end,
                    color: AppColors.danger,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (widget.isVideo) ...[
                    const SizedBox(width: 20),
                    _CallBtn(
                      icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                      onTap: () {
                        setState(() => _cameraOff = !_cameraOff);
                        _callService.engine?.muteLocalVideoStream(_cameraOff);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CallBtn({required this.icon, this.color = Colors.white24, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(radius: 28, backgroundColor: color, child: Icon(icon, color: Colors.white)),
    );
  }
}
