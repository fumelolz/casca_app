import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/scan_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_quantity_modal.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _notFoundStatus = 404;

class AddOutcome {
  const AddOutcome(this.message, {this.added = false, this.notFound = false});

  final String message;
  final bool added;
  final bool notFound;
}

Future<AddOutcome?> addItemToCart(
  BuildContext context,
  WidgetRef ref,
  PosCatalogItemModel item,
) async {
  final name = item.displayName;
  if (!isAvailable(item)) return AddOutcome('$name está agotado.');
  final controller = ref.read(cartProvider.notifier);

  var quantity = 1.0;
  if (item.allowsDecimalQuantity) {
    final typed = await showCascaModal<double>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => PosQuantityModal(item: item),
    );
    if (typed == null || !context.mounted) return null;
    quantity = typed;
  }

  final before = ref.read(cartProvider).quantityOf(item);
  controller.add(item, quantity);
  return ref.read(cartProvider).quantityOf(item) > before
      ? AddOutcome('Agregado: $name', added: true)
      : AddOutcome('No hay más existencias de $name.');
}

Future<AddOutcome?> addCodeToCart(
  BuildContext context,
  WidgetRef ref,
  String raw,
) async {
  final code = normalizeScannedCode(raw);
  final PosCatalogItemModel item;
  try {
    item = await ref
        .read(posRepositoryProvider)
        .findByCode(code, priceListId: ref.read(cartProvider).priceListId);
  } catch (error) {
    final notFound =
        error is ApiException && error.statusCode == _notFoundStatus;
    return AddOutcome(
      notFound
          ? 'No hay un producto con el código $code.'
          : apiErrorMessage(error, 'No fue posible buscar el código.'),
      notFound: notFound,
    );
  }
  if (!context.mounted) return null;
  return addItemToCart(context, ref, item);
}
