import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../models/post_model.dart';
import '../../../theme/app_theme.dart';
import '../../profile/user_profile_screen.dart';
import '../post_detail_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  static const _typeLabel = {
    'post': 'โพสต์',
    'question': '❓ คำถาม',
    'note': '📝 โน้ต',
    'homework': '📚 การบ้าน',
  };

  Future<void> _openAuthorProfile(BuildContext context, AppState appState) async {
    final author = await appState.firestoreService.getUser(post.authorId);
    if (author != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: author)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser?.uid ?? '';
    final isLiked = post.likedBy.contains(uid);
    final isSaved = post.savedBy.contains(uid);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(context, appState),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: post.authorPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(post.authorPhoto)
                        : null,
                    child: post.authorPhoto.isEmpty
                        ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?')
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openAuthorProfile(context, appState),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(timeago.format(post.createdAt, locale: 'th'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                if (post.type != 'post')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                    child: Text(_typeLabel[post.type] ?? post.type,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            if (post.subject.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('#${post.subject}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 8),
            Text(post.text, style: const TextStyle(fontSize: 14.5, height: 1.4)),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: PageView(
                    children: post.imageUrls
                        .map((url) => CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _ActionChip(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.danger : AppColors.textSecondary,
                  label: '${post.likeCount}',
                  onTap: () => appState.firestoreService.toggleLike(post.id, uid, isLiked),
                ),
                const SizedBox(width: 16),
                _ActionChip(
                  icon: Icons.mode_comment_outlined,
                  color: AppColors.textSecondary,
                  label: '${post.commentCount}',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                ),
                const Spacer(),
                _ActionChip(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.accent : AppColors.textSecondary,
                  label: '',
                  onTap: () => appState.firestoreService.toggleSave(post.id, uid, isSaved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
