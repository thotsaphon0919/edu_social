import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// ครูต้องแนบเอกสารยืนยันตัวตน (บัตรครู / หนังสือรับรองจากโรงเรียน ฯลฯ)
/// isVerifiedTeacher จะเป็น false จนกว่าแอดมินจะตรวจสอบเอกสารและอนุมัติ
/// (ตรวจสอบผ่าน Firebase Console หรือสร้างหน้า Admin แยกต่างหาก)
class RegisterTeacherScreen extends StatefulWidget {
  const RegisterTeacherScreen({super.key});

  @override
  State<RegisterTeacherScreen> createState() => _RegisterTeacherScreenState();
}

class _RegisterTeacherScreenState extends State<RegisterTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  File? _docFile;
  bool _loading = false;
  String? _error;

  Future<void> _pickDoc() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _docFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_docFile == null) {
      setState(() => _error = 'กรุณาแนบเอกสารยืนยันตัวตนครู (บัตรครู/หนังสือรับรอง)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = context.read<AppState>();
      final storage = StorageService();
      final docUrl = await storage.uploadFile(_docFile!, 'teacher_verification_docs');

      await appState.authService.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        username: _usernameCtrl.text.trim(),
        role: UserRole.teacher,
        school: _schoolCtrl.text.trim(),
        subjects: _subjectsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        teacherDocUrl: docUrl,
      );
      await appState.refreshUser();
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('สมัครสำเร็จ! บัญชีของคุณรอการตรวจสอบยืนยันตัวตนครู'),
        ));
      }
    } catch (e) {
      setState(() => _error = 'สมัครไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก - ครู')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้ (Username)'),
              validator: (v) => (v == null || v.isEmpty) ? 'กรอกชื่อผู้ใช้' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'อีเมล'),
              validator: (v) => (v == null || !v.contains('@')) ? 'กรอกอีเมลให้ถูกต้อง' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              validator: (v) => (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolCtrl,
              decoration: const InputDecoration(labelText: 'โรงเรียน / สถาบัน'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectsCtrl,
              decoration: const InputDecoration(
                  labelText: 'วิชาที่สอน (คั่นด้วยจุลภาค)', hintText: 'คณิตศาสตร์, ฟิสิกส์'),
            ),
            const SizedBox(height: 20),
            Text('เอกสารยืนยันตัวตนครู', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('แนบบัตรประจำตัวครู หรือหนังสือรับรองจากโรงเรียน เพื่อป้องกันการปลอมตัว',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDoc,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _docFile == null
                    ? const Center(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_file_rounded, size: 36, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('แตะเพื่ออัปโหลดเอกสาร'),
                        ],
                      ))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_docFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}
