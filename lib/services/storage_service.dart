import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadFile(File file, String folder) async {
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('$folder/$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultiple(List<File> files, String folder) async {
    final urls = <String>[];
    for (final f in files) {
      urls.add(await uploadFile(f, folder));
    }
    return urls;
  }
}
