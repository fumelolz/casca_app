import 'package:casca_app/core/errors/api_exception.dart';

String apiErrorMessage(Object error, String fallback, {String? forbidden}) {
  if (error is! ApiException) return fallback;
  if (forbidden != null && error.statusCode == 403) return forbidden;
  return error.serverMessage ??
      (error.type == ApiErrorType.network ? error.message : fallback);
}
