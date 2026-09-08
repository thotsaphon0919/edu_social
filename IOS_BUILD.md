# การสร้างไฟล์ iOS ด้วย Git + GitHub Actions

โปรเจกต์นี้เดิมมีแค่โค้ด Flutter (`lib/`) แต่ยังไม่มีโฟลเดอร์ `ios/`
เนื่องจากการสร้างไฟล์ iOS ที่ถูกต้อง (Xcode project, Podfile ฯลฯ) ต้องใช้ Flutter
บนเครื่อง macOS จริง จึงใช้ **GitHub Actions (macOS runner)** เป็นตัวสร้างให้แทน

## ขั้นตอน

1. Push โปรเจกต์นี้ขึ้น GitHub (ดูคำสั่งที่แชตให้ไว้)
2. ไปที่แท็บ **Actions** ของ repo → เลือก workflow **"iOS - Generate & Build"**
   → กด **Run workflow** (หรือรอให้รันอัตโนมัติเมื่อ push เข้า `main`)
3. รอบแรก workflow จะ:
   - รัน `flutter create --platforms=ios .` บน macOS จริง เพื่อสร้างโฟลเดอร์ `ios/`
     ที่ถูกต้อง 100%
   - เติมสิทธิ์ที่จำเป็นใน `Info.plist` (กล้อง/ไมค์/รูปภาพ สำหรับฟีเจอร์
     วิดีโอคอลและอัปโหลดรูป)
   - **commit โฟลเดอร์ `ios/` กลับเข้า repo ให้อัตโนมัติ**
   - build แอปแบบ unsigned แล้วแนบเป็น Artifact ให้ดาวน์โหลด (ใช้ทดสอบบน
     Simulator ได้ ยังลงเครื่องจริง/App Store ไม่ได้)
4. หลังจากนี้ทุกครั้งที่ push โค้ด workflow จะ build ซ้ำให้อัตโนมัติ (จะไม่สร้าง
   `ios/` ใหม่เพราะมีอยู่แล้ว)

## ถ้าต้องการลงเครื่องจริง / ขึ้น TestFlight / App Store

ต้องมี Apple Developer Program account แล้วเพิ่ม secrets ต่อไปนี้ใน repo
(Settings → Secrets and variables → Actions):

- Certificate (.p12) + รหัสผ่าน
- Provisioning profile
- App Store Connect API key (ถ้าจะ upload อัตโนมัติ)

แล้วแก้ step `flutter build ios --release --no-codesign` ในไฟล์
`.github/workflows/ios-build.yml` เป็น `flutter build ipa` พร้อมตั้งค่า
codesigning จาก secrets เหล่านี้ — บอกได้เลยถ้าต้องการให้ตั้งส่วนนี้ให้ด้วย
