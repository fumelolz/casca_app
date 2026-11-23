import 'dart:async';

import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/errors/api_exception.dart';

const unauthorized = ApiException(type: ApiErrorType.unauthorized);

SessionState fakeSession() => SessionState.fromJson({
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'X'},
  'roles': [],
  'hasTenant': false,
  'hasCompletedOnboarding': false,
});

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.hasSession = false, this.loginError, this.gate});

  static const validCode = '123456';
  static const duplicatedEmail = 'duplicado@casca.com';

  bool hasSession;
  Object? loginError;
  Completer<void>? gate;

  bool loggedOut = false;
  final requestedEmails = <String>[];
  final passwordChanges = <String>[];
  final registrations = <RegisterRequest>[];

  @override
  Future<SessionState> me() async {
    if (!hasSession) throw unauthorized;
    return fakeSession();
  }

  @override
  Future<SessionState> login({
    required String email,
    required String password,
  }) async {
    await gate?.future;
    final error = loginError;
    if (error != null) throw error;
    hasSession = true;
    return fakeSession();
  }

  @override
  Future<SessionState> registerAdmin(RegisterRequest request) async {
    await gate?.future;
    if (request.email == duplicatedEmail) {
      throw const ApiException(type: ApiErrorType.client, statusCode: 409);
    }
    registrations.add(request);
    hasSession = true;
    return fakeSession();
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    hasSession = false;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await gate?.future;
    requestedEmails.add(email);
  }

  @override
  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await gate?.future;
    if (code != validCode) {
      throw const ApiException(
        type: ApiErrorType.client,
        serverMessage: 'El código no es válido.',
      );
    }
    return 'token-$email';
  }

  @override
  Future<void> changePassword({
    required String sessionToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    passwordChanges.add('$sessionToken|$newPassword');
  }
}
