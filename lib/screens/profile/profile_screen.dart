import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../feed/widgets/post_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser?.uid;
    if (uid == null) return const SizedBox();

    // ใช้ stream สดจาก Firestore แทนข้อมูลที่ cache ไว้ใน AppState
    // เพื่อให้เห็นการเปลี่ยนแปลงทันที (เช่น แอดมินอนุมัติครู, แก้โปรไฟล์)
    // โดยไม่ต้องออกจากแอปแล้วเข้าใหม่
    return StreamBuilder<AppUser?>(
      stream: appState.firestoreService.streamUser(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const SizedBox();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('โปรไฟล์', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await appState.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                          context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                    }
                  },
                ),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          backgroundImage:
                              user.photoUrl.isNotEmpty ? CachedNetworkImageProvider(user.photoUrl) : null,
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
                            const SizedBox(width: 6),
                            if (user.role == UserRole.teacher)
                              Icon(Icons.workspace_premium_rounded,
                                  color: user.isVerifiedTeacher ? AppColors.teacherBadge : Colors.grey, size: 18),
                          ],
                        ),
                        Text(
                          user.role == UserRole.teacher
                              ? (user.isVerifiedTeacher ? 'ครู · ยืนยันตัวตนแล้ว' : 'ครู · รอการยืนยันตัวตน')
                              : 'นักเรียน${user.grade.isNotEmpty ? " · ${user.grade}" : ""}',
                          style: TextStyle(
                              color: (user.role == UserRole.teacher && !user.isVerifiedTeacher)
                                  ? AppColors.accent
                                  : AppColors.textSecondary),
                        ),
                        if (user.school.isNotEmpty)
                          Text(user.school, style: const TextStyle(color: AppColors.textSecondary)),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(user.bio, textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 14),
                        if (user.subjects.isEmpty && user.skills.isEmpty)
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('เพิ่มวิชา/ทักษะที่สนใจ'),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              ...user.subjects
                                  .map((s) => Chip(label: Text(s), backgroundColor: AppColors.primary.withOpacity(0.1))),
                              ...user.skills
                                  .map((s) => Chip(label: Text(s), backgroundColor: AppColors.secondary.withOpacity(0.1))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [Tab(text: 'ผลงานของฉัน'), Tab(text: 'บันทึกไว้')],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _PostsList(stream: appState.firestoreService.streamUserPosts(user.uid)),
                  _PostsList(stream: appState.firestoreService.streamSavedPosts(user.uid)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PostsList extends StatelessWidget {
  final Stream<List<PostModel>> stream;
  const _PostsList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: stream,
      builder: (context, snap) {
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('ยังไม่มีรายการ')));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => PostCard(post: posts[i]),
        );
      },
    );
  }
}
