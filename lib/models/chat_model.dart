class ChatModel {
  final String id;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;
  final bool isGroup;
  final String groupName;
  final String groupPhoto;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderId;

  ChatModel({
    required this.id,
    required this.memberIds,
    required this.memberNames,
    required this.memberPhotos,
    this.isGroup = false,
    this.groupName = '',
    this.groupPhoto = '',
    this.lastMessage = '',
    required this.lastMessageAt,
    this.lastSenderId = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'memberPhotos': memberPhotos,
        'isGroup': isGroup,
        'groupName': groupName,
        'groupPhoto': groupPhoto,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
        'lastSenderId': lastSenderId,
      };

  factory ChatModel.fromMap(Map<String, dynamic> map) => ChatModel(
        id: map['id'] ?? '',
        memberIds: List<String>.from(map['memberIds'] ?? []),
        memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
        memberPhotos: Map<String, String>.from(map['memberPhotos'] ?? {}),
        isGroup: map['isGroup'] ?? false,
        groupName: map['groupName'] ?? '',
        groupPhoto: map['groupPhoto'] ?? '',
        lastMessage: map['lastMessage'] ?? '',
        lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
            map['lastMessageAt'] ?? DateTime.now().millisecondsSinceEpoch),
        lastSenderId: map['lastSenderId'] ?? '',
      );

  String titleFor(String myUid) {
    if (isGroup) return groupName.isEmpty ? 'Group Chat' : groupName;
    final otherId = memberIds.firstWhere((id) => id != myUid, orElse: () => '');
    return memberNames[otherId] ?? 'Chat';
  }

  String photoFor(String myUid) {
    if (isGroup) return groupPhoto;
    final otherId = memberIds.firstWhere((id) => id != myUid, orElse: () => '');
    return memberPhotos[otherId] ?? '';
  }
}

enum MessageType { text, image, file, callLog }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String fileUrl;
  final String fileName;
  final MessageType type;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text = '',
    this.fileUrl = '',
    this.fileName = '',
    this.type = MessageType.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'type': type.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        text: map['text'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        fileName: map['fileName'] ?? '',
        type: MessageType.values.firstWhere(
            (t) => t.name == (map['type'] ?? 'text'),
            orElse: () => MessageType.text),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      );
}

// Teacher tutoring session request
class CallRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String subject;
  final DateTime requestedTime;
  final String status; // pending | accepted | rejected | done
  final String channelName; // Agora channel
  final String callType; // voice | video

  CallRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.requestedTime,
    this.status = 'pending',
    required this.channelName,
    this.callType = 'video',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'subject': subject,
        'requestedTime': requestedTime.millisecondsSinceEpoch,
        'status': status,
        'channelName': channelName,
        'callType': callType,
      };

  factory CallRequestModel.fromMap(Map<String, dynamic> map) => CallRequestModel(
        id: map['id'] ?? '',
        studentId: map['studentId'] ?? '',
        studentName: map['studentName'] ?? '',
        teacherId: map['teacherId'] ?? '',
        teacherName: map['teacherName'] ?? '',
        subject: map['subject'] ?? '',
        requestedTime: DateTime.fromMillisecondsSinceEpoch(
            map['requestedTime'] ?? DateTime.now().millisecondsSinceEpoch),
        status: map['status'] ?? 'pending',
        channelName: map['channelName'] ?? '',
        callType: map['callType'] ?? 'video',
      );
}

// Teacher's free time slot
class AvailabilitySlot {
  final String id;
  final String teacherId;
  final DateTime start;
  final DateTime end;
  final bool isBooked;

  AvailabilitySlot({
    required this.id,
    required this.teacherId,
    required this.start,
    required this.end,
    this.isBooked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'teacherId': teacherId,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'isBooked': isBooked,
      };

  factory AvailabilitySlot.fromMap(Map<String, dynamic> map) => AvailabilitySlot(
        id: map['id'] ?? '',
        teacherId: map['teacherId'] ?? '',
        start: DateTime.fromMillisecondsSinceEpoch(
            map['start'] ?? DateTime.now().millisecondsSinceEpoch),
        end: DateTime.fromMillisecondsSinceEpoch(
            map['end'] ?? DateTime.now().millisecondsSinceEpoch),
        isBooked: map['isBooked'] ?? false,
      );
}
