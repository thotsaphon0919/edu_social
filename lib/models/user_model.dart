enum UserRole { student, teacher }

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String photoUrl;
  final String bio;
  final UserRole role;
  final String school;
  final String grade; // students
  final List<String> subjects; // subjects studying / teaching
  final List<String> skills; // interests / skills
  final bool isVerifiedTeacher; // teachers only
  final String teacherDocUrl; // uploaded credential doc, for verification
  final int followerCount;
  final int followingCount;
  final String fcmToken; // ใช้ส่ง Push Notification หา user คนนี้
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl = '',
    this.bio = '',
    required this.role,
    this.school = '',
    this.grade = '',
    this.subjects = const [],
    this.skills = const [],
    this.isVerifiedTeacher = false,
    this.teacherDocUrl = '',
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
    this.fcmToken = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'role': role.name,
      'school': school,
      'grade': grade,
      'subjects': subjects,
      'skills': skills,
      'isVerifiedTeacher': isVerifiedTeacher,
      'teacherDocUrl': teacherDocUrl,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      bio: map['bio'] ?? '',
      role: (map['role'] == 'teacher') ? UserRole.teacher : UserRole.student,
      school: map['school'] ?? '',
      grade: map['grade'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      isVerifiedTeacher: map['isVerifiedTeacher'] ?? false,
      teacherDocUrl: map['teacherDocUrl'] ?? '',
      followerCount: map['followerCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      fcmToken: map['fcmToken'] ?? '',
    );
  }

  AppUser copyWith({
    String? username,
    String? photoUrl,
    String? bio,
    String? school,
    String? grade,
    List<String>? subjects,
    List<String>? skills,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      username: username ?? this.username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      role: role,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      subjects: subjects ?? this.subjects,
      skills: skills ?? this.skills,
      isVerifiedTeacher: isVerifiedTeacher,
      teacherDocUrl: teacherDocUrl,
      followerCount: followerCount,
      followingCount: followingCount,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
