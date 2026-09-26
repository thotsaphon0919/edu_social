import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app_state.dart';
import '../../models/chat_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../call/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendText() async {
    if (_textCtrl.text.trim().isEmpty) return;
    final appState = context.read<AppState>();
    final user = appState.currentUser!;
    final msg = MessageModel(
      id: appState.firestoreService.newId(),
      senderId: user.uid,
      senderName: user.username,
      text: _textCtrl.text.trim(),
      type: MessageType.text,
      createdAt: DateTime.now(),
    );
    _textCtrl.clear();
    await appState.firestoreService.sendMessage(widget.chat.id, msg);
  }

  Future<void> _sendImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser!;
      final url = await StorageService().uploadFile(File(picked.path), 'chat_images');
      final msg = MessageModel(
        id: appState.firestoreService.newId(),
        senderId: user.uid,
        senderName: user.username,
        fileUrl: url,
        type: MessageType.image,
        createdAt: DateTime.now(),
      );
      await appState.firestoreService.sendMessage(widget.chat.id, msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    setState(() => _sending = true);
    try {
      final appState = context.read<AppState>();
      final user = appState.currentUser!;
      final file = File(result.files.single.path!);
      final url = await StorageService().uploadFile(file, 'chat_files');
      final msg = MessageModel(
        id: appState.firestoreService.newId(),
        senderId: user.uid,
        senderName: user.username,
        fileUrl: url,
        fileName: result.files.single.name,
        type: MessageType.file,
        createdAt: DateTime.now(),
      );
      await appState.firestoreService.sendMessage(widget.chat.id, msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCall({required bool video}) {
    final appState = context.read<AppState>();
    final channelName = 'chat_${widget.chat.id}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: channelName,
          isVideo: video,
          remoteName: widget.chat.titleFor(appState.currentUser!.uid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.chat.photoFor(uid).isNotEmpty
                  ? CachedNetworkImageProvider(widget.chat.photoFor(uid))
                  : null,
              child: widget.chat.photoFor(uid).isEmpty
                  ? Icon(widget.chat.isGroup ? Icons.groups_rounded : Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.chat.titleFor(uid), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (!widget.chat.isGroup) ...[
            IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => _startCall(video: false)),
            IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _startCall(video: true)),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: appState.firestoreService.streamMessages(widget.chat.id),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[messages.length - 1 - i];
                    final isMe = msg.senderId == uid;
                    return _MessageBubble(msg: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image_outlined), onPressed: _sending ? null : _sendImage),
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: _sending ? null : _sendFile),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary), onPressed: _sendText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.primary : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.textPrimary;

    Widget content;
    switch (msg.type) {
      case MessageType.image:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: msg.fileUrl, width: 180, fit: BoxFit.cover),
        );
        break;
      case MessageType.file:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: textColor),
            const SizedBox(width: 6),
            Flexible(child: Text(msg.fileName, style: TextStyle(color: textColor))),
          ],
        );
        break;
      default:
        content = Text(msg.text, style: TextStyle(color: textColor));
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 2),
            child: Text(msg.senderName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: content,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(timeago.format(msg.createdAt, locale: 'th'),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
