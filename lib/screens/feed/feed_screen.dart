import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/post_model.dart';
import '../../theme/app_theme.dart';
import 'create_post_screen.dart';
import 'widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _sortBy = 'recent';
  String _typeFilter = 'all'; // all | post | question | note | homework
  String _searchQuery = '';

  static const _typeFilters = {
    'all': 'ทั้งหมด',
    'post': 'โพสต์',
    'question': '❓ คำถาม',
    'note': '📝 โน้ต',
    'homework': '📚 การบ้าน',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduSocial', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'recent', child: Text('ล่าสุด')),
              PopupMenuItem(value: 'popular', child: Text('ยอดนิยม (Like มากสุด)')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        icon: const Icon(Icons.add),
        label: const Text('โพสต์'),
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาโพสต์ หรือวิชา...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          // ตัวกรองตามหมวด (คล้าย Reddit - เลือกดูเฉพาะคำถาม/โน้ต/การบ้าน)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _typeFilters.entries.map((e) {
                final selected = _typeFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _typeFilter = e.key),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: appState.firestoreService.streamFeed(sortBy: _sortBy),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var posts = snap.data ?? [];

                if (_typeFilter != 'all') {
                  posts = posts.where((p) => p.type == _typeFilter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  posts = posts
                      .where((p) =>
                          p.text.toLowerCase().contains(_searchQuery) ||
                          p.subject.toLowerCase().contains(_searchQuery) ||
                          p.authorName.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (posts.isEmpty) {
                  return const Center(child: Text('ไม่พบโพสต์ที่ตรงกับเงื่อนไข'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => PostCard(post: posts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
