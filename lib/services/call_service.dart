import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

/// ⚠️ ต้องสมัคร Agora.io (มี Free tier) แล้วนำ App ID มาใส่ที่นี่
/// https://console.agora.io -> Create Project -> copy App ID
const String kAgoraAppId = 'YOUR_AGORA_APP_ID_HERE';

/// Production ควรสร้าง Token จาก backend server (Agora token server)
/// สำหรับทดสอบ ใช้ App ID โหมด "Testing Mode" (ไม่ต้องใช้ token) ได้ก่อน
class CallService {
  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  Future<void> requestPermissions({bool video = true}) async {
    await [
      Permission.microphone,
      if (video) Permission.camera,
    ].request();
  }

  Future<RtcEngine> initEngine() async {
    if (_engine != null) return _engine!;
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: kAgoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    return _engine!;
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
    bool video = true,
    String token = '', // '' works only in Agora testing mode
  }) async {
    final eng = await initEngine();
    if (video) {
      await eng.enableVideo();
      await eng.startPreview();
    } else {
      await eng.disableVideo();
    }
    await eng.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }

  Future<void> dispose() async {
    await _engine?.release();
    _engine = null;
  }
}
