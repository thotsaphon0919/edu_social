import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/post_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  String _type = 'post';
  final List<File> _images = [];
  bool _loading = false;

  final _types = const {
    'post': 'โพสต์ทั่วไป',
    'question': '❓ คำถาม',
    'note': '📝 โน้ต/สรุป',
    'homework': '📚 การบ้าน',
  };

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submit() async {
    if (_textCtrl.text.trim().isEmpty && _images.isEmpty) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser!;
      final storage = StorageService();
      final urls = _images.isEmpty ? <String>[] : await storage.uploadMultiple(_images, 'post_images');

      final post = PostModel(
        id: appState.firestoreService.newId(),
        authorId: user.uid,
        authorName: user.username,
        authorPhoto: user.photoUrl,
        text: _textCtrl.text.trim(),
        imageUrls: urls,
        subject: _subjectCtrl.text.trim(),
        type: _type,
        createdAt: DateTime.now(),
      );
      await appState.firestoreService.createPost(post);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppState>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างโพสต์'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('โพสต์', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(user?.username.isNotEmpty == true ? user!.username[0] : '?')),
              const SizedBox(width: 10),
              Text(user?.username ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _types.entries.map((e) {
              final selected = _type == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _type = e.key),
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'แบ่งปันผลงาน โน้ต หรือคำถามของคุณ...'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(labelText: 'วิชา (เช่น คณิตศาสตร์)', prefixIcon: Icon(Icons.tag)),
          ),
          const SizedBox(height: 16),
          if (_images.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_images[i], width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: const CircleAvatar(
                            radius: 12, backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.image_outlined),
            label: const Text('เพิ่มรูปภาพ'),
          ),
        ],
      ),
    );
  }
}
