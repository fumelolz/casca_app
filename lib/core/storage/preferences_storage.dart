import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesStorage {
  PreferencesStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String themeModeKey = 'casca.theme_mode';
  static const String sidebarCollapsedKey = 'casca.sidebar_collapsed';
  static const String labelPrinterKey = 'casca.label_printer';
  static const String ticketPrinterKey = 'casca.ticket_printer';

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      return;
    }
  }
}

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => PreferencesStorage(),
);
