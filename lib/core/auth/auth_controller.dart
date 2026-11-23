import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AuthState {
  const AuthState._(this.status, this.session);

  const AuthState.initializing() : this._(AuthStatus.initializing, null);

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
    try {
      final session = await _repository.me();
      state = AuthState.authenticated(session);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    state = AuthState.authenticated(session);
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
