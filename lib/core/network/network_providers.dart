import 'package:casca_app/core/config/app_config.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/auth_refresh_interceptor.dart';
import 'package:casca_app/core/network/secure_cookie_storage.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiredSignal extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() => state++;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredSignal, int>(
  SessionExpiredSignal.new,
);

final cookieJarProvider = Provider<CookieJar>(
  (ref) => PersistCookieJar(storage: SecureCookieStorage()),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );

  dio.interceptors.addAll([
    CookieManager(ref.watch(cookieJarProvider)),
    AuthRefreshInterceptor(
      dio: dio,
      onSessionExpired: () =>
          ref.read(sessionExpiredProvider.notifier).notifyExpired(),
    ),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider), ref.watch(cookieJarProvider)),
);
