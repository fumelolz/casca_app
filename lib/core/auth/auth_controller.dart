import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus {
  initializing,
  connectionFailed,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState._(this.status, this.session);

  const AuthState.initializing() : this._(AuthStatus.initializing, null);

  const AuthState.connectionFailed()
    : this._(AuthStatus.connectionFailed, null);

  const AuthState.authenticated(SessionState session)
    : this._(AuthStatus.authenticated, session);

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  final AuthStatus status;
  final SessionState? session;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen(sessionExpiredProvider, (previous, next) {
      state = const AuthState.unauthenticated();
    });
    Future.microtask(restoreSession);
    return const AuthState.initializing();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    if (state.status == AuthStatus.connectionFailed) {
      state = const AuthState.initializing();
    }
    try {
      final session = await _repository.me();
      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      final transient =
          error.type == ApiErrorType.network ||
          error.type == ApiErrorType.server ||
          error.type == ApiErrorType.unknown;
      state = transient
          ? const AuthState.connectionFailed()
          : const AuthState.unauthenticated();
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    state = AuthState.authenticated(session);
  }

  Future<void> register(RegisterRequest request) async {
    final session = await _repository.registerAdmin(request);
    state = AuthState.authenticated(session);
  }

  void applySession(SessionState session) {
    if (state.status != AuthStatus.authenticated) return;
    state = AuthState.authenticated(session);
  }

  Future<void> refreshSession() async {
    try {
      applySession(await _repository.me());
    } on ApiException {
      return;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthState.unauthenticated();
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
