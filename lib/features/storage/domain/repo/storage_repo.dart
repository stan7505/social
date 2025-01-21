import 'dart:typed_data';

abstract class StorageRepo {
  Future<String?> uploadProfileImageMobile(String path, String fileName);

  Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName);

  Future<String?> uploadPostoMobile(String path, String fileName);

  Future<String?> uploadPostoWeb(Uint8List fileBytes, String fileName);
}
