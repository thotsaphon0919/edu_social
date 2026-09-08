import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import 'group_create_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final me = appState.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เริ่มแชทใหม่'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreateScreen())),
            icon: const Icon(Icons.groups_outlined),
            label: const Text('สร้างกลุ่ม'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                  hintText: 'ค้นหาชื่อผู้ใช้...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final users = snap.data!.docs
                    .map((d) => AppUser.fromMap(d.data() as Map<String, dynamic>))
                    .where((u) => u.uid != me.uid)
                    .where((u) => _query.isEmpty || u.username.toLowerCase().contains(_query))
                    .toList();
                if (users.isEmpty) return const Center(child: Text('ไม่พบผู้ใช้'));
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(u.username.isNotEmpty ? u.username[0] : '?')),
                      title: Row(
                        children: [
                          Text(u.username),
                          if (u.role == UserRole.teacher) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.teacherBadge),
                          ],
                        ],
                      ),
                      subtitle: Text(u.role == UserRole.teacher ? 'ครู · ${u.school}' : 'นักเรียน · ${u.school}'),
                      onTap: () async {
                        final chatId = await appState.firestoreService.getOrCreateDirectChat(me, u);
                        if (context.mounted) {
                          Navigator.pop(context);
                          final chats = await appState.firestoreService.streamMyChats(me.uid).first;
                          final chat = chats.firstWhere((c) => c.id == chatId);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
