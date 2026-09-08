class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final List<String> imageUrls;
  final String subject; // ป้ายกำกับวิชา
  final String type; // 'post' | 'question' | 'note' | 'homework'
  final List<String> likedBy;
  final List<String> savedBy;
  // จำนวน Like แบบ denormalized เก็บแยกไว้ต่างหาก เพื่อให้ Firestore
  // เรียง (orderBy) ตามความนิยมได้ตรงๆ ฝั่ง server แทนที่จะต้องดึงโพสต์
  // ทั้งหมดมาเรียงเองฝั่ง client (ซึ่ง likedBy.length ทำไม่ได้เพราะ
  // Firestore ไม่รองรับ orderBy ตามความยาวของ array)
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    this.imageUrls = const [],
    this.subject = '',
    this.type = 'post',
    this.likedBy = const [],
    this.savedBy = const [],
    int? likeCount,
    this.commentCount = 0,
    required this.createdAt,
  }) : likeCount = likeCount ?? likedBy.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'imageUrls': imageUrls,
      'subject': subject,
      'type': type,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final likedBy = List<String>.from(map['likedBy'] ?? []);
    return PostModel(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhoto: map['authorPhoto'] ?? '',
      text: map['text'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      subject: map['subject'] ?? '',
      type: map['type'] ?? 'post',
      likedBy: likedBy,
      savedBy: List<String>.from(map['savedBy'] ?? []),
      // เอกสารเก่าก่อนมี field นี้ (migration) ให้ fallback ไปนับจาก likedBy.length
      likeCount: map['likeCount'] ?? likedBy.length,
      commentCount: map['commentCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhoto': authorPhoto,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
        id: map['id'] ?? '',
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? '',
        authorPhoto: map['authorPhoto'] ?? '',
        text: map['text'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      );
}
