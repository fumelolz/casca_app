enum ApiErrorType { network, unauthorized, client, server, unknown }

class ApiException implements Exception {
  const ApiException({required this.type, this.statusCode, this.serverMessage});

  final ApiErrorType type;
  final int? statusCode;
  final String? serverMessage;

  String get message => serverMessage ?? _defaultMessage(type);

  bool get isUnauthorized => type == ApiErrorType.unauthorized;

  static String _defaultMessage(ApiErrorType type) {
    return switch (type) {
      ApiErrorType.network => 'No se pudo conectar con el servidor.',
      ApiErrorType.unauthorized => 'Tu sesión no es válida.',
      ApiErrorType.client => 'La solicitud no es válida.',
      ApiErrorType.server => 'El servidor no pudo procesar la solicitud.',
      ApiErrorType.unknown => 'Ocurrió un error inesperado.',
    };
  }

  @override
  String toString() => 'ApiException($type, $statusCode, $message)';
}
