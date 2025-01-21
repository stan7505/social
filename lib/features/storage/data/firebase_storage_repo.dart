// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social/features/storage/domain/repo/storage_repo.dart';

class FirebaseStorageRepo implements StorageRepo {
  final firebaseStorage = FirebaseStorage.instance;


  @override
  Future<String?> uploadProfileImageMobile(String path, String fileName) async {
    return uploadFile(path, fileName, 'profile_images');
  }

  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName) {
    return uploadFileWeb(fileBytes, fileName, 'profile_images');
  }

  // MOBILE
  Future<String?> uploadFile(String path, String fileName, String folder) async {
    try {
      // get file
      final file = File(path);

      //find place to store file
      final Storageref = firebaseStorage.ref().child('$folder/$fileName');

      // upload file
      final uploadTask = Storageref.putFile(file);

      // get download url
      final downloadUrl = await (await uploadTask).ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // WEB
  Future<String?> uploadFileWeb(Uint8List fileBytes, String fileName, String folder) async {
    try {
      final Storageref = firebaseStorage.ref().child('$folder/$fileName');
      final uploadTask = Storageref.putData(fileBytes);
      final downloadUrl = await (await uploadTask).ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadImageChat(PlatformFile imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = firebaseStorage.ref().child('chat_images').child(fileName);

    UploadTask uploadTask;
    if (kIsWeb) {
      uploadTask = storageRef.putData(imageFile.bytes!);
    } else {
      uploadTask = storageRef.putFile(File(imageFile.path!));
    }

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Future<String?> uploadPostoMobile(String path, String fileName) {
    return uploadFile(path, fileName, 'post_images');
  }

  @override
  Future<String?> uploadPostoWeb(Uint8List fileBytes, String fileName) {
    return uploadFileWeb(fileBytes, fileName, 'post_images');
  }
}
