import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'teacher_profile_screen.dart';
import 'teacher_schedule_screen.dart';

class TeacherDirectoryScreen extends StatefulWidget {
  const TeacherDirectoryScreen({super.key});

  @override
  State<TeacherDirectoryScreen> createState() => _TeacherDirectoryScreenState();
}

class _TeacherDirectoryScreenState extends State<TeacherDirectoryScreen> {
  List<AppUser> _teachers = [];
  bool _loading = true;
  String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    final teachers = await appState.firestoreService.searchTeachers(subject: _subjectFilter);
    setState(() {
      _teachers = teachers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isTeacher = appState.currentUser?.role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ติวสด', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isTeacher)
            TextButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const TeacherScheduleScreen())),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('เวลาว่างของฉัน'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'ค้นหาวิชา เช่น คณิตศาสตร์', prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) {
                _subjectFilter = v.trim().isEmpty ? null : v.trim();
                _load();
              },
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_teachers.isEmpty)
            const Expanded(child: Center(child: Text('ไม่พบครูในขณะนี้')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _teachers.length,
                itemBuilder: (_, i) {
                  final t = _teachers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(radius: 26, child: Text(t.username.isNotEmpty ? t.username[0] : '?')),
                      title: Row(
                        children: [
                          Text(t.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          if (t.isVerifiedTeacher)
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.teacherBadge)
                          else
                            const Text('(รอยืนยัน)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.school),
                          Text('สอน: ${t.subjects.join(", ")}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => TeacherProfileScreen(teacher: t))),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
