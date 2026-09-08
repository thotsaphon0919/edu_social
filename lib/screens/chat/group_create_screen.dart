import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  List<AppUser> _allUsers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    final me = context.read<AppState>().currentUser!.uid;
    setState(() {
      _allUsers = snap.docs
          .map((d) => AppUser.fromMap(d.data()))
          .where((u) => u.uid != me)
          .toList();
    });
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedIds.length < 2) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final me = appState.currentUser!;
      final members = [me, ..._allUsers.where((u) => _selectedIds.contains(u.uid))];
      final chatId = await appState.firestoreService.createGroupChat(
        members: members,
        groupName: _nameCtrl.text.trim(),
      );
      if (mounted) {
        final chats = await appState.firestoreService.streamMyChats(me.uid).first;
        final chat = chats.firstWhere((c) => c.id == chatId);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างกลุ่มแชท'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _create,
            child: const Text('สร้าง', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อกลุ่ม', prefixIcon: Icon(Icons.groups_outlined)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text('เลือกสมาชิก (อย่างน้อย 2 คน)')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (_, i) {
                final u = _allUsers[i];
                final selected = _selectedIds.contains(u.uid);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedIds.add(u.uid);
                    } else {
                      _selectedIds.remove(u.uid);
                    }
                  }),
                  title: Text(u.username),
                  secondary: CircleAvatar(child: Text(u.username.isNotEmpty ? u.username[0] : '?')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
