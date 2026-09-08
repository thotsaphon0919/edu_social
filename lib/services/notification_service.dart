import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// จัดการ Push Notification ทั้งหมด:
/// 1. ขอ permission แจ้งเตือน
/// 2. ขอ FCM token แล้วบันทึกลง Firestore (users/{uid}/fcmToken) เพื่อให้ Cloud Function ส่งหาได้ตรงเครื่อง
/// 3. แสดง notification ตอนแอปเปิดอยู่ (foreground) ด้วย flutter_local_notifications
/// 4. จัดการตอนผู้ใช้แตะ notification เพื่อนำทางไปหน้าที่เกี่ยวข้อง (แชท/คำขอติว)
///
/// ฝั่งเซิร์ฟเวอร์ (Cloud Functions) เป็นตัวส่ง notification จริง ดูใน /functions

/// ต้องเป็น top-level function (นอก class) สำหรับ background handler ตามข้อกำหนดของ firebase_messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ไม่ต้องทำอะไรเพิ่ม ระบบปฏิบัติการจะโชว์ notification ให้เองตอนแอปอยู่ background/ปิดอยู่
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// callback ให้ main app เซ็ตเพื่อนำทางตอนแตะ notification
  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> init() async {
    // 1) ขอ permission (จำเป็นบน iOS และ Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2) ตั้งค่า local notifications สำหรับแสดงตอนแอปเปิดอยู่ (foreground)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onNotificationTap != null) {
          final data = Uri.splitQueryString(response.payload!);
          onNotificationTap!(data);
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3) แสดง notification ตอนแอปเปิดอยู่ (foreground) - ปกติ FCM จะไม่โชว์ banner ให้เองตอนนี้
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: Uri(queryParameters: message.data).query,
        );
      }
    });

    // 4) ตอนแตะ notification ขณะแอปอยู่ background (ไม่ได้ถูกปิดสนิท)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });

    // 5) กรณีเปิดแอปจาก notification ตอนแอปถูกปิดสนิทอยู่ (terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // หน่วงเล็กน้อยให้ UI พร้อมก่อนค่อยนำทาง
      Future.delayed(const Duration(milliseconds: 800), () {
        onNotificationTap?.call(initialMessage.data);
      });
    }
  }

  /// เรียกหลัง login/register สำเร็จ เพื่อบันทึก FCM token ของเครื่องนี้ลง Firestore
  Future<void> saveTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': token});

    // อัปเดต token ใหม่ทุกครั้งที่ระบบ refresh (เช่นลงแอปใหม่)
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': newToken});
    });
  }

  /// เรียกตอน logout เพื่อล้าง token (กันแจ้งเตือนหลุดไปเครื่องเก่า)
  Future<void> clearTokenForUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': ''});
    } catch (_) {
      // เพิกเฉยถ้า doc ไม่มีแล้วหรือไม่มีสิทธิ์ (เช่นหลุด session ไปแล้ว)
    }
  }
}
