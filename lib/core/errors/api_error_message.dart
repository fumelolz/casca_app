import 'package:casca_app/core/errors/api_exception.dart';

String apiErrorMessage(Object error, String fallback) {
  if (error is! ApiException) return fallback;
  return error.serverMessage ??
      (error.type == ApiErrorType.network ? error.message : fallback);
}
