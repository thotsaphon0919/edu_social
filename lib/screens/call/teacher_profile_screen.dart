import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'call_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  final AppUser teacher;
  const TeacherProfileScreen({super.key, required this.teacher});

  Future<void> _requestSlot(BuildContext context, AvailabilitySlot slot) async {
    final appState = context.read<AppState>();
    final student = appState.currentUser!;
    final callType = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.call), title: const Text('โทรเสียง (Voice Call)'),
              onTap: () => Navigator.pop(context, 'voice')),
          ListTile(
              leading: const Icon(Icons.videocam), title: const Text('วิดีโอคอล (Video Call)'),
              onTap: () => Navigator.pop(context, 'video')),
        ]),
      ),
    );
    if (callType == null) return;

    final requestId = appState.firestoreService.newId();
    final channelName = 'tutor_$requestId';
    final req = CallRequestModel(
      id: requestId,
      studentId: student.uid,
      studentName: student.username,
      teacherId: teacher.uid,
      teacherName: teacher.username,
      subject: teacher.subjects.isNotEmpty ? teacher.subjects.first : '',
      requestedTime: slot.start,
      channelName: channelName,
      callType: callType,
    );
    await appState.firestoreService.requestCall(req);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ส่งคำขอติวแล้ว'),
        content: Text('รอครู ${teacher.username} ตอบรับคำขอของคุณ...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );

    // Listen for teacher's response and auto navigate to call when accepted
    appState.firestoreService.streamCallRequestStatus(requestId).listen((r) {
      if (r != null && r.status == 'accepted' && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close dialog if open
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelName: r.channelName,
              isVideo: r.callType == 'video',
              remoteName: teacher.username,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(teacher.username)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 44, child: Text(teacher.username.isNotEmpty ? teacher.username[0] : '?', style: const TextStyle(fontSize: 30))),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(teacher.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (teacher.isVerifiedTeacher) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: AppColors.teacherBadge),
                    ],
                  ],
                ),
                Text(teacher.school, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('วิชาที่สอน', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: teacher.subjects
                .map((s) => Chip(label: Text(s), backgroundColor: AppColors.primary.withOpacity(0.1)))
                .toList(),
          ),
          const SizedBox(height: 20),
          if (teacher.bio.isNotEmpty) ...[
            Text('เกี่ยวกับฉัน', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(teacher.bio),
            const SizedBox(height: 20),
          ],
          Text('เวลาว่างที่จองได้', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<AvailabilitySlot>>(
            stream: appState.firestoreService.streamTeacherAvailability(teacher.uid),
            builder: (context, snap) {
              final slots = (snap.data ?? []).where((s) => !s.isBooked && s.start.isAfter(DateTime.now())).toList();
              if (slots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('ครูยังไม่ได้เปิดเวลาว่าง', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: slots.map((s) {
                  final fmt = DateFormat('EEE d MMM, HH:mm', 'th');
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: AppColors.primary),
                      title: Text('${fmt.format(s.start)} - ${DateFormat('HH:mm').format(s.end)}'),
                      trailing: ElevatedButton(
                        onPressed: () => _requestSlot(context, s),
                        child: const Text('ขอติว'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
