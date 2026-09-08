import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app_state.dart';
import '../../models/post_model.dart';
import '../../theme/app_theme.dart';
import '../profile/user_profile_screen.dart';
import 'widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser!;
      final comment = CommentModel(
        id: appState.firestoreService.newId(),
        authorId: user.uid,
        authorName: user.username,
        authorPhoto: user.photoUrl,
        text: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await appState.firestoreService.addComment(widget.post.id, comment);
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('โพสต์')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                PostCard(post: widget.post),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('ความคิดเห็น', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<CommentModel>>(
                  stream: appState.firestoreService.streamComments(widget.post.id),
                  builder: (context, snap) {
                    final comments = snap.data ?? [];
                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    return Column(
                      children: comments.map((c) => _CommentTile(comment: c)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(hintText: 'แสดงความคิดเห็น...'),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final appState = context.read<AppState>();
              final author = await appState.firestoreService.getUser(comment.authorId);
              if (author != null && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: author)));
              }
            },
            child: CircleAvatar(
              radius: 16,
              child: Text(comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(comment.text),
                  const SizedBox(height: 4),
                  Text(timeago.format(comment.createdAt, locale: 'th'),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
