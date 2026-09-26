import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new account. [role] is 'student' or 'teacher'.
  Future<AppUser> register({
    required String email,
    required String password,
    required String username,
    required UserRole role,
    String school = '',
    String grade = '',
    List<String> subjects = const [],
    String teacherDocUrl = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(username);

    final appUser = AppUser(
      uid: cred.user!.uid,
      username: username,
      email: email,
      role: role,
      school: school,
      grade: grade,
      subjects: subjects,
      // Teachers start unverified until an admin/document review approves them.
      isVerifiedTeacher: false,
      teacherDocUrl: teacherDocUrl,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
    return appUser;
  }

  Future<AppUser?> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<AppUser?> fetchCurrentAppUser() async {
    final u = currentUser;
    if (u == null) return null;
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }
}
