/**
 * Cloud Functions สำหรับ EduSocial
 * ทำหน้าที่ "ส่ง" Push Notification จริง (ฝั่งแอปทำได้แค่รับ/แสดงผล ส่งหาเครื่องอื่นไม่ได้)
 *
 * Trigger ทั้งหมด:
 * 1. onNewMessage        - มีข้อความแชทใหม่ -> แจ้งเตือนสมาชิกคนอื่นในแชท (ยกเว้นคนส่ง)
 * 2. onNewCallRequest    - นักเรียนขอติว -> แจ้งเตือนครู
 * 3. onCallRequestAccepted - ครูกดรับคำขอ -> แจ้งเตือนนักเรียนให้เข้าห้องโทร
 *
 * Deploy: firebase deploy --only functions
 */

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/** ส่ง notification ไปหลาย token พร้อมกัน (กรอง token ว่างออกก่อนเสมอ) */
async function sendToTokens(tokens, notification, data) {
  const validTokens = tokens.filter((t) => !!t);
  if (validTokens.length === 0) return;

  const stringData = {};
  for (const key in data) {
    stringData[key] = String(data[key]);
  }

  try {
    const response = await messaging.sendEachForMulticast({
      tokens: validTokens,
      notification,
      data: stringData,
      android: { priority: "high" },
    });
    logger.info(`ส่งสำเร็จ ${response.successCount}/${validTokens.length}`);
  } catch (err) {
    logger.error("ส่ง notification ล้มเหลว", err);
  }
}

// ============ 1) ข้อความแชทใหม่ ============
exports.onNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const message = event.data?.data();
  const { chatId } = event.params;
  if (!message) return;

  const chatDoc = await db.collection("chats").doc(chatId).get();
  if (!chatDoc.exists) return;
  const chat = chatDoc.data();

  const memberIds = (chat.memberIds || []).filter((id) => id !== message.senderId);
  if (memberIds.length === 0) return;

  const userDocs = await db.getAll(...memberIds.map((id) => db.collection("users").doc(id)));
  const tokens = userDocs.map((d) => d.data()?.fcmToken).filter(Boolean);

  const title = chat.isGroup ? `${chat.groupName || "กลุ่มแชท"} · ${message.senderName}` : message.senderName;
  const body =
    message.type === "image" ? "📷 ส่งรูปภาพ" : message.type === "file" ? "📎 ส่งไฟล์แนบ" : message.text || "ข้อความใหม่";

  await sendToTokens(tokens, { title, body }, { type: "chat", chatId });
});

// ============ 2) นักเรียนส่งคำขอติว -> แจ้งครู ============
exports.onNewCallRequest = onDocumentCreated("call_requests/{requestId}", async (event) => {
  const req = event.data?.data();
  if (!req) return;

  const teacherDoc = await db.collection("users").doc(req.teacherId).get();
  const token = teacherDoc.data()?.fcmToken;
  if (!token) return;

  await sendToTokens(
    [token],
    {
      title: "คำขอติวใหม่",
      body: `${req.studentName} ขอติว${req.subject ? ` วิชา${req.subject}` : ""}`,
    },
    { type: "call_request", requestId: event.params.requestId },
  );
});

// ============ 3) ครูกดรับคำขอ -> แจ้งนักเรียนให้เข้าห้องโทร ============
exports.onCallRequestAccepted = onDocumentUpdated("call_requests/{requestId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;

  // ยิงแจ้งเตือนเฉพาะตอนสถานะเปลี่ยนเป็น accepted เท่านั้น (กันยิงซ้ำตอน field อื่นเปลี่ยน)
  if (before.status === after.status || after.status !== "accepted") return;

  const studentDoc = await db.collection("users").doc(after.studentId).get();
  const token = studentDoc.data()?.fcmToken;
  if (!token) return;

  await sendToTokens(
    [token],
    {
      title: "ครูตอบรับคำขอติวแล้ว!",
      body: `${after.teacherName} พร้อมเข้าห้องโทรกับคุณแล้ว แตะเพื่อเข้าร่วม`,
    },
    {
      type: "call",
      channelName: after.channelName,
      callType: after.callType,
      remoteName: after.teacherName,
    },
  );
});
