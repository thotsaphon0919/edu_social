import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app_state.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// ใช้ navigator นี้เพื่อนำทางจากการแตะ push notification ได้จากทุกที่ในแอป
/// (ไม่มี BuildContext ปกติตอนแอปเพิ่งเปิดจาก notification)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  timeago.setLocaleMessages('th', timeago.ThMessages());

  // ต้องลงทะเบียน background handler ก่อน runApp เสมอ
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const EduSocialApp());
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
