import 'package:casca_app/core/auth/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _store(String id, {bool isDefault = false}) => {
  'id': id,
  'name': 'Tienda $id',
  'taxesEnabled': true,
  'isDefault': isDefault,
  'tenantId': 't1',
  'tenantName': 'Casca Demo',
  'businessType': 'abarrotes',
};

Map<String, dynamic> _loginJson({Object? permissions}) => {
  'account': {'id': 'a1', 'email': 'dany@casca.com', 'name': 'Dany'},
  'roles': [
    {'id': 'r1', 'name': 'Admin'},
  ],
  'permissions': ?permissions,
  'store': _store('s1', isDefault: true),
  'stores': [_store('s1', isDefault: true), _store('s2')],
  'tenantName': 'Casca Demo',
};

void main() {
  test('construye la sesión completa desde la respuesta de login', () {
    final session = SessionState.fromJson(
      _loginJson(permissions: ['products.read', 'sales.create']),
    );

    expect(session.account.email, 'dany@casca.com');
    expect(session.activeStore.id, 's1');
    expect(session.stores.map((s) => s.id), ['s1', 's2']);
    expect(session.roles.single.name, 'Admin');
  });

  test('si la respuesta no trae permissions usa una lista vacía', () {
    final session = SessionState.fromJson(_loginJson());

    expect(session.permissions, isEmpty);
    expect(session.hasPermission('products.read'), isFalse);
  });

  test('acepta una respuesta sin lista de tiendas', () {
    final json = _loginJson()..remove('stores');

    final session = SessionState.fromJson(json);

    expect(session.stores, isEmpty);
  });

  test('rechaza una respuesta sin tienda activa', () {
    expect(
      () => SessionState.fromJson(_loginJson()..remove('store')),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => SessionState.fromJson(_loginJson()..['store'] = null),
      throwsA(isA<TypeError>()),
    );
  });

  test('hasPermission indica si la sesión incluye el permiso', () {
    final session = SessionState.fromJson(
      _loginJson(permissions: ['products.read']),
    );

    expect(session.hasPermission('products.read'), isTrue);
    expect(session.hasPermission('sales.create'), isFalse);
  });
}
