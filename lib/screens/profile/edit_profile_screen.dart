import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _gradeCtrl;
  late List<String> _subjects;
  late List<String> _skills;
  File? _newPhoto;
  bool _loading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _usernameCtrl = TextEditingController(text: user.username);
    _bioCtrl = TextEditingController(text: user.bio);
    _schoolCtrl = TextEditingController(text: user.school);
    _gradeCtrl = TextEditingController(text: user.grade);
    _subjects = List<String>.from(user.subjects);
    _skills = List<String>.from(user.skills);
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = 'กรุณากรอกชื่อผู้ใช้');
      return;
    }
    setState(() {
      _usernameError = null;
      _loading = true;
    });
    try {
      final appState = context.read<AppState>();
      final uid = appState.currentUser!.uid;
      String? photoUrl;
      if (_newPhoto != null) {
        photoUrl = await StorageService().uploadFile(_newPhoto!, 'profile_photos');
      }
      await appState.firestoreService.updateUserProfile(uid, {
        'username': username,
        'bio': _bioCtrl.text.trim(),
        'school': _schoolCtrl.text.trim(),
        'grade': _gradeCtrl.text.trim(),
        'subjects': _subjects,
        'skills': _skills,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      await appState.refreshUser();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppState>().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: _newPhoto != null
                        ? FileImage(_newPhoto!)
                        : (user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) as ImageProvider : null),
                    child: (_newPhoto == null && user.photoUrl.isEmpty)
                        ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 30, color: AppColors.primary))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('แตะรูปเพื่อเปลี่ยน', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameCtrl,
            decoration: InputDecoration(labelText: 'ชื่อผู้ใช้', errorText: _usernameError),
            onChanged: (_) {
              if (_usernameError != null) setState(() => _usernameError = null);
            },
          ),
          const SizedBox(height: 14),
          TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 14),
          TextField(controller: _schoolCtrl, decoration: const InputDecoration(labelText: 'โรงเรียน/สถาบัน')),
          const SizedBox(height: 14),
          if (user.role == UserRole.student) ...[
            TextField(controller: _gradeCtrl, decoration: const InputDecoration(labelText: 'ระดับชั้น')),
            const SizedBox(height: 14),
          ],
          _TagInput(
            label: user.role == UserRole.teacher ? 'วิชาที่สอน' : 'วิชาที่สนใจ',
            hint: 'พิมพ์ชื่อวิชาแล้วกด Enter เช่น คณิตศาสตร์',
            tags: _subjects,
            color: AppColors.primary,
            onChanged: (v) => setState(() => _subjects = v),
          ),
          const SizedBox(height: 14),
          _TagInput(
            label: 'ทักษะ / ความสนใจ',
            hint: 'พิมพ์แล้วกด Enter เช่น วาดรูป, เขียนโปรแกรม',
            tags: _skills,
            color: AppColors.secondary,
            onChanged: (v) => setState(() => _skills = v),
          ),
        ],
      ),
    );
  }
}

/// ช่องกรอกแบบ Chip - พิมพ์แล้วกด Enter เพื่อเพิ่มเป็น tag, กด x ที่ chip เพื่อลบ
/// ใช้แทนช่อง comma-separated เดิมที่พิมพ์ผิดง่ายและลบทีละรายการไม่ได้
class _TagInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> tags;
  final Color color;
  final ValueChanged<List<String>> onChanged;

  const _TagInput({
    required this.label,
    required this.hint,
    required this.tags,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _ctrl = TextEditingController();

  void _addTag(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (widget.tags.any((t) => t.toLowerCase() == v.toLowerCase())) {
      _ctrl.clear();
      return;
    }
    widget.onChanged([...widget.tags, v]);
    _ctrl.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.tags
                      .map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 13)),
                            backgroundColor: widget.color.withOpacity(0.12),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeTag(t),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              if (widget.tags.isNotEmpty) const SizedBox(height: 6),
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => _addTag(_ctrl.text),
                  ),
                ),
                onSubmitted: _addTag,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
