# EduSocial — แอปโซเชียลเพื่อการเรียนรู้ (Flutter)

แอปสไตล์ Twitter + Instagram สำหรับนักเรียน/ครู: Feed แชร์ผลงาน, DM/Group Chat,
Voice/Video Call ระหว่างนักเรียน-ครู, ระบบสมัครแยก Student/Teacher พร้อม verify ครู,
โปรไฟล์, Like/Save

โค้ดทั้งหมดเป็นของจริง ต่อกับ **Firebase** (Auth, Firestore, Storage) และ
**Agora.io** (Voice/Video call) — ใช้งานได้จริงทันทีที่ตั้งค่า 2 บริการนี้เสร็จ
(ทั้งคู่มี Free tier เพียงพอสำหรับพัฒนา/เดโม)

---

## 1) โครงสร้างโปรเจกต์

```
lib/
  models/        -> User, Post, Comment, Chat, Message, CallRequest, AvailabilitySlot
  services/      -> AuthService, FirestoreService, StorageService, CallService(Agora)
  theme/         -> ธีมสี ฟอนต์ แนวการศึกษา
  screens/
    auth/        -> Login, เลือก Role, สมัคร Student, สมัคร Teacher (+แนบเอกสาร verify)
    home/        -> Bottom nav หลัก
    feed/        -> Feed, สร้างโพสต์, รายละเอียดโพสต์ + คอมเมนต์
    chat/        -> รายการแชท, ห้องแชท (ข้อความ/รูป/ไฟล์), เริ่มแชทใหม่, สร้างกลุ่ม
    call/        -> รายชื่อครู, โปรไฟล์ครู+เวลาว่าง, ตารางเวลาของครู, หน้าจอ Call จริง
    profile/     -> โปรไฟล์ตัวเอง, แก้ไขโปรไฟล์
firestore.rules   -> กฎความปลอดภัย Firestore
storage.rules     -> กฎความปลอดภัย Storage
```

## 2) ติดตั้ง Flutter dependencies

```bash
flutter pub get
```

## 3) ตั้งค่า Firebase (จำเป็น — ไม่มีขั้นตอนนี้แอปรันไม่ได้)

1. สร้างโปรเจกต์ที่ https://console.firebase.google.com
2. เปิดใช้งาน **Authentication → Email/Password**
3. สร้าง **Firestore Database** (โหมด production หรือ test ก็ได้ตอนพัฒนา)
4. เปิดใช้งาน **Storage**
5. ติดตั้ง FlutterFire CLI แล้วรันคำสั่งนี้ในโฟลเดอร์โปรเจกต์:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

คำสั่งนี้จะสร้างไฟล์ `lib/firebase_options.dart` ให้อัตโนมัติ (ทับไฟล์ placeholder เดิม)
พร้อมตั้งค่า Android/iOS ให้เอง

6. Deploy security rules (แนะนำ):

```bash
firebase deploy --only firestore:rules,storage:rules
```

## 4) ตั้งค่า Agora (สำหรับ Voice/Video Call)

1. สมัครที่ https://console.agora.io (ฟรี)
2. สร้าง Project ใหม่ โหมด **"App ID without a certificate"** (Testing Mode — ง่ายสุดสำหรับเริ่มต้น)
3. คัดลอก **App ID** มาใส่ที่ไฟล์:

```dart
// lib/services/call_service.dart
const String kAgoraAppId = 'ใส่ App ID ของคุณตรงนี้';
```

> ⚠️ Testing Mode ไม่ต้องใช้ Token แต่ **ไม่ปลอดภัยสำหรับ production**
> เมื่อจะขึ้น production จริง ให้เปิดโหมด "App ID + Token" และสร้าง token
> ผ่าน backend server ของคุณเอง (ดูเอกสาร Agora: Token Server)

## 5) สิทธิ์ที่ต้องเพิ่มในแต่ละแพลตฟอร์ม

**Android** (`android/app/src/main/AndroidManifest.xml`) เพิ่มก่อน `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH" />
```
และตั้ง `minSdkVersion 21` ขึ้นไปใน `android/app/build.gradle`

**iOS** (`ios/Runner/Info.plist`) เพิ่ม:
```xml
<key>NSCameraUsageDescription</key>
<string>ใช้กล้องสำหรับวิดีโอคอลติวเรียน</string>
<key>NSMicrophoneUsageDescription</key>
<string>ใช้ไมโครโฟนสำหรับการโทร</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>ใช้เลือกรูปภาพสำหรับโพสต์และโปรไฟล์</string>
```

## 6) รันแอป

```bash
flutter run
```

---

## 7) ตั้งค่า Push Notification (ใหม่)

ฟีเจอร์นี้มี 2 ฝั่ง: **ฝั่งแอป** (โค้ด Dart จัดการให้แล้วในโปรเจกต์นี้ ไม่ต้องแก้อะไรเพิ่ม) และ **ฝั่งเซิร์ฟเวอร์** (Cloud Functions ที่โฟลเดอร์ `functions/` — ต้อง deploy เองเพราะเป็นโค้ด Node.js แยกจากแอป)

### 7.1 เพิ่มสิทธิ์ใน Android Manifest

เปิดไฟล์ `android/app/src/main/AndroidManifest.xml` เพิ่ม permission นี้ **ก่อน** แท็ก `<application>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

และเพิ่ม meta-data นี้ **ข้างใน** แท็ก `<application>` (ตั้ง default notification channel):
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="edu_social_default" />
```

### 7.2 Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

ครั้งแรกที่ deploy อาจต้องเปิดใช้งาน **Cloud Functions API** และ **Cloud Build API** ก่อน (ระบบจะมีลิงก์ให้กดเปิดอัตโนมัติถ้ายังไม่เปิด) และต้องอยู่บน **Blaze plan** เท่านั้น (มีอยู่แล้วจากตอนตั้งค่า Storage)

### 7.3 ทดสอบ

หลัง build แอปใหม่และ deploy Cloud Functions เสร็จ ลองส่งข้อความแชทจากอีกบัญชีดู — เครื่องปลายทางควรได้รับแจ้งเตือนแม้ปิดแอปอยู่ (ทดสอบด้วย 2 เครื่องจริงเท่านั้น เพราะ FCM ต้องมีเครื่องจริงรับ token)

ดู log ของ Cloud Functions เพื่อ debug ได้ด้วย:
```bash
firebase functions:log
```

### 7.4 การแจ้งเตือนที่รองรับตอนนี้
| เหตุการณ์ | แจ้งเตือนไปหาใคร | แตะแล้วไปไหน |
|---|---|---|
| มีข้อความแชทใหม่ (DM/กลุ่ม) | สมาชิกคนอื่นในแชท | เปิดห้องแชทนั้นทันที |
| นักเรียนส่งคำขอติว | ครูที่ถูกขอ | (แจ้งเตือนอย่างเดียว ครูเข้าแอปไปดูคำขอเอง) |
| ครูกดรับคำขอติว | นักเรียนที่ขอ | เข้าห้องโทรทันที |



| ฟีเจอร์ | สถานะ |
|---|---|
| สมัคร/ล็อกอิน แยก Student/Teacher | ✅ ทำงานได้จริงผ่าน Firebase Auth |
| แนบเอกสารยืนยันตัวตนครู | ✅ อัปโหลดขึ้น Storage, รอ Admin อนุมัติ (ดูหมายเหตุด้านล่าง) |
| Feed โพสต์รูป+ข้อความ, คอมเมนต์, Like, เรียงตามยอดนิยม | ✅ Real-time ผ่าน Firestore |
| Save/Bookmark โพสต์ | ✅ |
| DM 1:1 และ Group Chat (ข้อความ/รูป/ไฟล์) | ✅ Real-time |
| Voice/Video Call นักเรียน↔ครู | ✅ ผ่าน Agora RTC (ต้องใส่ App ID) |
| ครูกำหนดเวลาว่าง + นักเรียนขอจองติว + accept/reject | ✅ |
| โปรไฟล์ (รูป, bio, โรงเรียน, วิชา, ทักษะ, ผลงาน) | ✅ |
| ดูโปรไฟล์สาธารณะของผู้ใช้คนอื่น + แชทได้ทันทีจากโปรไฟล์ | ✅ |
| ค้นหา + กรองโพสต์ตามหมวด (คำถาม/โน้ต/การบ้าน) | ✅ |
| Push Notification (ข้อความใหม่, คำขอติว, ครูตอบรับ) | ✅ ต้อง deploy Cloud Functions ตามข้อ 7 |

### หมายเหตุสำคัญ: ระบบ Verify ครู
ในโค้ดชุดนี้ ครูที่สมัครใหม่จะมี `isVerifiedTeacher = false` เสมอ และอัปโหลดเอกสาร
ยืนยันตัวตนเก็บไว้ที่ Storage (`teacherDocUrl`) — เพื่อความปลอดภัย การอนุมัติ
(`isVerifiedTeacher = true`) **ควรทำผ่าน Firebase Console หรือสร้างหน้า Admin
แยกต่างหาก** (เช่น Cloud Function ที่ตรวจสอบเอกสารแล้วอัปเดต Firestore) ไม่ควร
ให้ client แก้ไขค่านี้เอง — ใน `firestore.rules` จึงยังไม่ได้เปิดให้ user
ทั่วไปแก้ไขฟิลด์นี้ได้อย่างอิสระ ควรเพิ่ม Cloud Function/Custom Claims เพิ่มเติม
สำหรับ production

### แนวทางขยายต่อ (ไม่ได้รวมในโค้ดชุดนี้ เพื่อไม่ให้ใหญ่เกินไป)
- หน้า Admin สำหรับอนุมัติครู
- Follow/Unfollow ระหว่างผู้ใช้
- Search โพสต์/ผู้ใช้แบบเต็มรูปแบบ (แนะนำ Algolia สำหรับ full-text search)
- Ringing/incoming-call UI แบบ real-time (ปัจจุบันใช้การ poll สถานะผ่าน Firestore stream)
