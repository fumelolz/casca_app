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
  'hasTenant': true,
  'hasCompletedOnboarding': false,
  'tenantName': 'Casca Demo',
};

void main() {
  test('construye la sesión completa desde la respuesta de login', () {
    final session = SessionState.fromJson(
      _loginJson(permissions: ['products.read', 'sales.create']),
    );

    expect(session.account.email, 'dany@casca.com');
    expect(session.activeStore?.id, 's1');
    expect(session.stores.map((s) => s.id), ['s1', 's2']);
    expect(session.roles.single.name, 'Admin');
    expect(session.hasCompletedOnboarding, isFalse);
  });

  test('si la respuesta no trae permissions usa una lista vacía', () {
    final session = SessionState.fromJson(_loginJson());

    expect(session.permissions, isEmpty);
    expect(session.hasPermission('products.read'), isFalse);
  });

  test('acepta una sesión sin tienda activa ni lista de tiendas', () {
    final json = _loginJson()
      ..remove('store')
      ..remove('stores')
      ..['hasTenant'] = false;

    final session = SessionState.fromJson(json);

    expect(session.activeStore, isNull);
    expect(session.stores, isEmpty);
    expect(session.hasTenant, isFalse);
  });

  test('acepta store y stores en null explícito', () {
    final json = _loginJson()
      ..['store'] = null
      ..['stores'] = null;

    final session = SessionState.fromJson(json);

    expect(session.activeStore, isNull);
    expect(session.stores, isEmpty);
  });

  test('hasPermission indica si la sesión incluye el permiso', () {
    final session = SessionState.fromJson(
      _loginJson(permissions: ['products.read']),
    );

    expect(session.hasPermission('products.read'), isTrue);
    expect(session.hasPermission('sales.create'), isFalse);
  });
}
