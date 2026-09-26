import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app_state.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// ใช้ navigator นี้เพื่อนำทางจากการแตะ push notification ได้จากทุกที่ในแอป
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // แทนที่จอเทา/ขาวเปล่า ๆ ของ Flutter ด้วยข้อความ error ที่อ่านได้จริง
  ErrorWidget.builder = (FlutterErrorDetails details) => _ErrorBox(
        title: 'เกิดข้อผิดพลาดในหน้าจอนี้',
        message: details.exceptionAsString(),
      );

  // ***สำคัญ***: ทุกอย่างก่อน runApp ต้องอยู่ใน try
  // ถ้ามีอะไร throw ที่นี่แล้วไม่จับ = runApp ไม่เคยถูกเรียก = "จอขาว"
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    timeago.setLocaleMessages('th', timeago.ThMessages());
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    runApp(const EduSocialApp());
  } catch (e, st) {
    debugPrint('❌ Startup failed: $e\n$st');
    runApp(StartupErrorApp(error: e, stack: st));
  }
}

class EduSocialApp extends StatelessWidget {
  const EduSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'EduSocial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}

/// จอแสดงสาเหตุตอนเปิดแอปไม่ผ่าน — ดีกว่าจอขาวเพราะบอกได้ว่าพังตรงไหน
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ErrorBox(
        title: 'เปิดแอปไม่สำเร็จ',
        message: '$error',
        detail: kReleaseMode ? null : '$stack',
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.title, required this.message, this.detail});

  final String title;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1B1F),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              if (detail != null) ...[
                const SizedBox(height: 16),
                SelectableText(
                  detail!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
