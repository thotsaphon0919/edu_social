import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController(); // comma separated
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = context.read<AppState>();
      await appState.authService.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        username: _usernameCtrl.text.trim(),
        role: UserRole.student,
        school: _schoolCtrl.text.trim(),
        grade: _gradeCtrl.text.trim(),
        subjects: _subjectsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      await appState.refreshUser();
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      setState(() => _error = 'สมัครไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก - นักเรียน')),
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
              decoration: const InputDecoration(labelText: 'โรงเรียน / มหาวิทยาลัย'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeCtrl,
              decoration: const InputDecoration(labelText: 'ระดับชั้น (เช่น ม.5, ปี 2)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectsCtrl,
              decoration: const InputDecoration(
                  labelText: 'วิชาที่สนใจ (คั่นด้วยจุลภาค)', hintText: 'คณิตศาสตร์, ฟิสิกส์, ภาษาอังกฤษ'),
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
