import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'main.dart' show navigatorKey;
import 'screens/chat/chat_screen.dart';
import 'screens/call/call_screen.dart';

class AppState extends ChangeNotifier {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  final NotificationService notificationService = NotificationService();

  AppUser? currentUser;
  bool loading = true;

  AppState() {
    _setupNotifications();
    authService.authStateChanges.listen((user) async {
      if (user == null) {
        currentUser = null;
      } else {
        currentUser = await authService.fetchCurrentAppUser();
        if (currentUser != null) {
          await notificationService.saveTokenForUser(currentUser!.uid);
        }
      }
      loading = false;
      notifyListeners();
    });
  }

  void _setupNotifications() {
    notificationService.init();
    notificationService.onNotificationTap = _handleNotificationTap;
  }

  /// นำทางไปหน้าที่เกี่ยวข้องตามชนิด notification ที่แตะ
  /// ข้อมูล data ที่ Cloud Function ส่งมาต้องมี key "type" เสมอ ('chat' | 'call')
  void _handleNotificationTap(Map<String, dynamic> data) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final type = data['type'];

    if (type == 'chat' && data['chatId'] != null) {
      final uid = currentUser?.uid;
      if (uid == null) return;
      final chats = await firestoreService.streamMyChats(uid).first;
      final match = chats.where((c) => c.id == data['chatId']);
      if (match.isNotEmpty) {
        nav.push(MaterialPageRoute(builder: (_) => ChatScreen(chat: match.first)));
      }
    } else if (type == 'call' && data['channelName'] != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: data['channelName'],
          isVideo: data['callType'] == 'video',
          remoteName: data['remoteName'] ?? '',
        ),
      ));
    }
  }

  Future<void> refreshUser() async {
    currentUser = await authService.fetchCurrentAppUser();
    if (currentUser != null) {
      await notificationService.saveTokenForUser(currentUser!.uid);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    if (currentUser != null) {
      await notificationService.clearTokenForUser(currentUser!.uid);
    }
    await authService.logout();
    currentUser = null;
    notifyListeners();
  }
}
