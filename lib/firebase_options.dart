// ไฟล์นี้เป็น "placeholder" — ต้องสร้างจริงด้วยคำสั่ง:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// คำสั่งนี้จะสร้างไฟล์ firebase_options.dart ทับไฟล์นี้อัตโนมัติ
// โดยดึงค่า config จริงจากโปรเจกต์ Firebase ของคุณ (Android/iOS/Web)
// ดูวิธีเต็มใน README.md หัวข้อ "Firebase Setup"

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions ยังไม่ได้ตั้งค่า — กรุณารันคำสั่ง `flutterfire configure` '
      'ตามที่อธิบายใน README.md ก่อนรันแอป (kIsWeb=$kIsWeb)',
    );
  }
}
