import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';

const String _genericSaleError =
    'No fue posible registrar la venta. Verifica que haya un turno de caja activo e inténtalo de nuevo.';
const String unconfirmedSaleError =
    'No pudimos confirmar si la venta se registró. Cobra otra vez con el mismo pago: no se duplicará.';

class SaleFailure {
  const SaleFailure({required this.message, this.lineErrors = const {}});

  final String message;
  final Map<String, String> lineErrors;
}

SaleFailure saleFailure(Object error, List<CartLine> submitted) {
  if (error is! ApiException) {
    return const SaleFailure(message: _genericSaleError);
  }
  if (error.type != ApiErrorType.client &&
      error.type != ApiErrorType.unauthorized) {
    return const SaleFailure(message: unconfirmedSaleError);
  }

  final lineErrors = <String, String>{};
  for (final detail in error.details) {
    final match = RegExp(
      r'^items\[(\d+)\]$',
      caseSensitive: false,
    ).firstMatch(detail.field ?? '');
    final index = int.tryParse(match?.group(1) ?? '');
    if (index == null || index >= submitted.length) continue;
    lineErrors.update(
      submitted[index].key,
      (current) => '$current ${detail.description}',
      ifAbsent: () => detail.description,
    );
  }

  final description = error.details.map((d) => d.description).join(' ');
  return SaleFailure(
    message: description.isNotEmpty
        ? description
        : error.serverMessage ?? _genericSaleError,
    lineErrors: lineErrors,
  );
}
