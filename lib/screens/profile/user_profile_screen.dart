import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../feed/widgets/post_card.dart';

/// หน้าโปรไฟล์สาธารณะ - ใช้ดูโปรไฟล์ของคนอื่น (กดจากชื่อ/รูปในโพสต์ คอมเมนต์ หรือรายชื่อครู)
/// ต่างจาก ProfileScreen ตรงที่เป็น read-only ไม่มีปุ่มแก้ไข/ออกจากระบบ
/// แต่มีปุ่ม "ส่งข้อความ" เพื่อเริ่มแชทได้ทันที
class UserProfileScreen extends StatelessWidget {
  final AppUser user;
  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final me = appState.currentUser;
    final isMe = me?.uid == user.uid;

    return Scaffold(
      appBar: AppBar(title: Text(user.username)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 32, color: AppColors.primary))
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (user.role == UserRole.teacher) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.workspace_premium_rounded,
                          color: user.isVerifiedTeacher ? AppColors.teacherBadge : Colors.grey, size: 18),
                    ],
                  ],
                ),
                Text(
                  user.role == UserRole.teacher ? 'ครู' : 'นักเรียน${user.grade.isNotEmpty ? " · ${user.grade}" : ""}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (user.school.isNotEmpty)
                  Text(user.school, style: const TextStyle(color: AppColors.textSecondary)),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(user.bio, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ...user.subjects.map((s) => Chip(label: Text(s), backgroundColor: AppColors.primary.withOpacity(0.1))),
                    ...user.skills.map((s) => Chip(label: Text(s), backgroundColor: AppColors.secondary.withOpacity(0.1))),
                  ],
                ),
                if (!isMe && me != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final chatId = await appState.firestoreService.getOrCreateDirectChat(me, user);
                      if (context.mounted) {
                        final chats = await appState.firestoreService.streamMyChats(me.uid).first;
                        final chat = chats.firstWhere((c) => c.id == chatId);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('ส่งข้อความ'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('ผลงานที่เคยโพสต์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          StreamBuilder<List<PostModel>>(
            stream: appState.firestoreService.streamUserPosts(user.uid),
            builder: (context, snap) {
              final posts = snap.data ?? [];
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('ยังไม่มีผลงานที่โพสต์', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: posts
                    .map((p) => Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(post: p)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
