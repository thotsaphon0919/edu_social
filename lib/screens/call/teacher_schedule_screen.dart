import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/chat_model.dart';
import '../../theme/app_theme.dart';
import 'call_screen.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  Future<void> _addSlot() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final startTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (startTime == null || !mounted) return;

    final start = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
    final end = start.add(const Duration(hours: 1));

    final appState = context.read<AppState>();
    final slot = AvailabilitySlot(
      id: appState.firestoreService.newId(),
      teacherId: appState.currentUser!.uid,
      start: start,
      end: end,
    );
    await appState.firestoreService.setAvailability(slot);
  }

  Future<void> _accept(CallRequestModel req) async {
    final appState = context.read<AppState>();
    await appState.firestoreService.updateCallStatus(req.id, 'accepted');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: req.channelName,
          isVideo: req.callType == 'video',
          remoteName: req.studentName,
        ),
      ),
    );
  }

  Future<void> _reject(CallRequestModel req) async {
    await context.read<AppState>().firestoreService.updateCallStatus(req.id, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('ตารางเวลาของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlot,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเวลาว่าง'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('คำขอติวเข้ามาใหม่', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<CallRequestModel>>(
            stream: appState.firestoreService.streamIncomingRequests(uid),
            builder: (context, snap) {
              final reqs = snap.data ?? [];
              if (reqs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('ยังไม่มีคำขอ', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: reqs.map((r) {
                  return Card(
                    child: ListTile(
                      leading: Icon(r.callType == 'video' ? Icons.videocam : Icons.call, color: AppColors.primary),
                      title: Text('${r.studentName} ขอติว${r.subject.isNotEmpty ? " วิชา${r.subject}" : ""}'),
                      subtitle: Text(DateFormat('EEE d MMM, HH:mm', 'th').format(r.requestedTime)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.check_circle, color: AppColors.secondary), onPressed: () => _accept(r)),
                          IconButton(icon: const Icon(Icons.cancel, color: AppColors.danger), onPressed: () => _reject(r)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('เวลาว่างของฉัน', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<AvailabilitySlot>>(
            stream: appState.firestoreService.streamTeacherAvailability(uid),
            builder: (context, snap) {
              final slots = snap.data ?? [];
              if (slots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('ยังไม่มีเวลาว่าง กด "เพิ่มเวลาว่าง" เพื่อเริ่มต้น', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: slots.map((s) {
                  final fmt = DateFormat('EEE d MMM, HH:mm', 'th');
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: s.isBooked ? AppColors.textSecondary : AppColors.secondary),
                      title: Text('${fmt.format(s.start)} - ${DateFormat('HH:mm').format(s.end)}'),
                      trailing: Text(s.isBooked ? 'จองแล้ว' : 'ว่าง',
                          style: TextStyle(color: s.isBooked ? AppColors.textSecondary : AppColors.secondary)),
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
