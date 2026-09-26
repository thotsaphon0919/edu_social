import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// จัดการ Push Notification ทั้งหมด
///
/// หมายเหตุสำหรับ iOS: ถ้า .ipa ถูกเซ็นด้วย free certificate / Sideloadly
/// จะไม่มี aps-environment entitlement → ลงทะเบียน APNs ไม่ได้ →
/// getToken() จะ throw ทุกครั้ง ทุกอย่างในไฟล์นี้จึงถูกครอบ try/catch ไว้
/// เพื่อไม่ให้แอปค้างหรือพังเพราะ push ใช้ไม่ได้
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ระบบปฏิบัติการจะโชว์ notification ให้เองตอนแอป background/ปิดอยู่
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> init() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // iOS: ให้ระบบโชว์ banner เองตอนแอปเปิดอยู่
      if (!kIsWeb && Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // ⚠️ เดิมขาด DarwinInitializationSettings → บน iOS แจ้งเตือน local ไม่ทำงาน
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && onNotificationTap != null) {
            onNotificationTap!(Uri.splitQueryString(response.payload!));
          }
        },
      );

      const channel = AndroidNotificationChannel(
        'edu_social_default',
        'การแจ้งเตือนทั่วไป',
        description: 'แจ้งเตือนข้อความ คำขอติว และการอัปเดตอื่นๆ',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'edu_social_default',
              'การแจ้งเตือนทั่วไป',
              channelDescription: 'แจ้งเตือนข้อความ คำขอติว และการอัปเดตอื่นๆ',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: Uri(queryParameters: message.data).query,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onNotificationTap?.call(message.data);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          onNotificationTap?.call(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService.init ล้มเหลว (แอปทำงานต่อได้): $e');
    }
  }

  /// คืน FCM token หรือ null ถ้าเครื่องนี้ใช้ push ไม่ได้ — ไม่ throw
  Future<String?> _safeToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // บน iOS ต้องได้ APNS token ก่อน ไม่งั้น getToken() จะ throw
        final apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint('⚠️ ยังไม่มี APNS token — ข้ามการบันทึก FCM token');
          return null;
        }
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('⚠️ getToken ล้มเหลว: $e');
      return null;
    }
  }

  Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _safeToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});

      _messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken}).catchError((_) {});
      });
    } catch (e) {
      debugPrint('⚠️ saveTokenForUser ล้มเหลว: $e');
    }
  }

  Future<void> clearTokenForUser(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': ''});
    } catch (_) {}
  }
}
