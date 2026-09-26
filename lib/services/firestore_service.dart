import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ---------------- USERS ----------------
  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateFcmToken(String uid, String token) {
    return _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<List<AppUser>> searchTeachers({String? subject}) async {
    Query q = _db.collection('users').where('role', isEqualTo: 'teacher');
    if (subject != null && subject.isNotEmpty) {
      q = q.where('subjects', arrayContains: subject);
    }
    final snap = await q.get();
    return snap.docs.map((d) => AppUser.fromMap(d.data() as Map<String, dynamic>)).toList();
  }

  // ---------------- POSTS ----------------
  Future<void> createPost(PostModel post) {
    return _db.collection('posts').doc(post.id).set(post.toMap());
  }

  Stream<List<PostModel>> streamFeed({String sortBy = 'recent'}) {
    // เรียงตาม popularity ด้วย field 'likeCount' (denormalized integer)
    // ตรงๆ ที่ Firestore แทนการดึงทุกโพสต์มา sort เองฝั่ง client
    Query q = _db.collection('posts');
    q = sortBy == 'popular'
        ? q.orderBy('likeCount', descending: true)
        : q.orderBy('createdAt', descending: true);
    return q.snapshots().map((snap) =>
        snap.docs.map((d) => PostModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  Future<void> toggleLike(String postId, String uid, bool isLiked) {
    final ref = _db.collection('posts').doc(postId);
    return ref.update({
      'likedBy': isLiked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
      // อัปเดตตัวนับคู่กับ array เสมอ ให้ทั้งสอง field sync กันในทุกครั้ง
      'likeCount': FieldValue.increment(isLiked ? -1 : 1),
    });
  }

  Future<void> toggleSave(String postId, String uid, bool isSaved) {
    final ref = _db.collection('posts').doc(postId);
    return ref.update({
      'savedBy': isSaved
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    final batch = _db.batch();
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc(comment.id);
    batch.set(commentRef, comment.toMap());
    final postRef = _db.collection('posts').doc(postId);
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Stream<List<CommentModel>> streamComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => CommentModel.fromMap(d.data())).toList());
  }

  Stream<List<PostModel>> streamSavedPosts(String uid) {
    return _db
        .collection('posts')
        .where('savedBy', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => PostModel.fromMap(d.data())).toList());
  }

  Stream<List<PostModel>> streamUserPosts(String uid) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PostModel.fromMap(d.data())).toList());
  }

  // ---------------- CHAT ----------------
  String newId() => _uuid.v4();

  Future<String> getOrCreateDirectChat(AppUser me, AppUser other) async {
    final existing = await _db
        .collection('chats')
        .where('isGroup', isEqualTo: false)
        .where('memberIds', arrayContains: me.uid)
        .get();

    for (final doc in existing.docs) {
      final chat = ChatModel.fromMap(doc.data());
      if (chat.memberIds.contains(other.uid) && chat.memberIds.length == 2) {
        return chat.id;
      }
    }

    final id = newId();
    final chat = ChatModel(
      id: id,
      memberIds: [me.uid, other.uid],
      memberNames: {me.uid: me.username, other.uid: other.username},
      memberPhotos: {me.uid: me.photoUrl, other.uid: other.photoUrl},
      isGroup: false,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
    );
    await _db.collection('chats').doc(id).set(chat.toMap());
    return id;
  }

  Future<String> createGroupChat({
    required List<AppUser> members,
    required String groupName,
  }) async {
    final id = newId();
    final chat = ChatModel(
      id: id,
      memberIds: members.map((m) => m.uid).toList(),
      memberNames: {for (final m in members) m.uid: m.username},
      memberPhotos: {for (final m in members) m.uid: m.photoUrl},
      isGroup: true,
      groupName: groupName,
      lastMessage: 'สร้างกลุ่มแล้ว',
      lastMessageAt: DateTime.now(),
    );
    await _db.collection('chats').doc(id).set(chat.toMap());
    return id;
  }

  Stream<List<ChatModel>> streamMyChats(String uid) {
    return _db
        .collection('chats')
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatModel.fromMap(d.data())).toList());
  }

  Future<void> sendMessage(String chatId, MessageModel msg) async {
    final batch = _db.batch();
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc(msg.id);
    batch.set(msgRef, msg.toMap());
    final chatRef = _db.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': msg.type == MessageType.text ? msg.text : '[ไฟล์แนบ]',
      'lastMessageAt': msg.createdAt.millisecondsSinceEpoch,
      'lastSenderId': msg.senderId,
    });
    await batch.commit();
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => MessageModel.fromMap(d.data())).toList());
  }

  // ---------------- CALLS / TUTORING ----------------
  Future<void> setAvailability(AvailabilitySlot slot) {
    return _db.collection('availability').doc(slot.id).set(slot.toMap());
  }

  Stream<List<AvailabilitySlot>> streamTeacherAvailability(String teacherId) {
    return _db
        .collection('availability')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('start')
        .snapshots()
        .map((s) => s.docs.map((d) => AvailabilitySlot.fromMap(d.data())).toList());
  }

  Future<void> requestCall(CallRequestModel req) async {
    await _db.collection('call_requests').doc(req.id).set(req.toMap());
  }

  Stream<List<CallRequestModel>> streamIncomingRequests(String teacherId) {
    return _db
        .collection('call_requests')
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => CallRequestModel.fromMap(d.data())).toList());
  }

  Stream<CallRequestModel?> streamCallRequestStatus(String requestId) {
    return _db.collection('call_requests').doc(requestId).snapshots().map(
        (d) => d.exists ? CallRequestModel.fromMap(d.data()!) : null);
  }

  Future<void> updateCallStatus(String requestId, String status) {
    return _db.collection('call_requests').doc(requestId).update({'status': status});
  }
}
