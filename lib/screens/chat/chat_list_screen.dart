import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app_state.dart';
import '../../models/chat_model.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('แชท', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: appState.firestoreService.streamMyChats(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snap.data ?? [];
          if (chats.isEmpty) {
            return const Center(child: Text('ยังไม่มีบทสนทนา เริ่มแชทกับเพื่อนได้เลย!'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final chat = chats[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage:
                      chat.photoFor(uid).isNotEmpty ? CachedNetworkImageProvider(chat.photoFor(uid)) : null,
                  child: chat.photoFor(uid).isEmpty
                      ? Icon(chat.isGroup ? Icons.groups_rounded : Icons.person)
                      : null,
                ),
                title: Text(chat.titleFor(uid), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(chat.lastMessage.isEmpty ? 'เริ่มบทสนทนา' : chat.lastMessage,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(timeago.format(chat.lastMessageAt, locale: 'th'),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat))),
              );
            },
          );
        },
      ),
    );
  }
}
