import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'register_student_screen.dart';
import 'register_teacher_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณคือ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('เลือกบทบาทของคุณเพื่อเริ่มต้นใช้งาน',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _RoleCard(
              icon: Icons.backpack_rounded,
              title: 'นักเรียน / นักศึกษา',
              subtitle: 'โพสต์ผลงาน ถามคำถาม แชทกับเพื่อน และขอติวกับครู',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RegisterStudentScreen())),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.workspace_premium_rounded,
              title: 'ครู / อาจารย์',
              subtitle: 'แบ่งปันความรู้ กำหนดเวลาว่าง และติวออนไลน์กับนักเรียน',
              color: AppColors.secondary,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RegisterTeacherScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
