import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_endpoints.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<SessionState> login({
    required String email,
    required String password,
  }) {
    return _api.post<SessionState>(
      AuthEndpoints.login,
      body: {'email': email, 'password': password},
      decode: _decodeSession,
    );
  }

  Future<SessionState> me() {
    return _api.get<SessionState>(AuthEndpoints.me, decode: _decodeSession);
  }

  Future<void> logout() async {
    try {
      await _api.postVoid(AuthEndpoints.logout);
    } finally {
      await _api.clearCookies();
    }
  }

  Future<void> forgotPassword({required String email}) {
    return _api.postVoid(AuthEndpoints.forgotPassword, body: {'email': email});
  }

  static SessionState _decodeSession(Object? data) {
    return SessionState.fromJson(data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
