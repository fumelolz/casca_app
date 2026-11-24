import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LastEmailStorage {
  LastEmailStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'casca.last_email';

  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String email) async {
    try {
      await _storage.write(key: _key, value: email);
    } catch (_) {
      return;
    }
  }
}

final lastEmailStorageProvider = Provider<LastEmailStorage>(
  (ref) => LastEmailStorage(),
);
