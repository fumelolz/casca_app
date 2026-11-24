import 'package:casca_app/core/storage/last_email_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('devuelve null si nunca se guardó un correo', () async {
    expect(await LastEmailStorage().read(), isNull);
  });

  test('devuelve el último correo guardado', () async {
    final storage = LastEmailStorage();
    await storage.write('a@casca.com');
    await storage.write('b@casca.com');
    expect(await storage.read(), 'b@casca.com');
  });
}
