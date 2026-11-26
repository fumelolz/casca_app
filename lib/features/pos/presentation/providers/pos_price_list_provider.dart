import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/pos/data/models/pos_price_list_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _applyPriceList = 'sale.applypricelist';
const String _customPrice = 'sale.customprice';

final posPriceListsProvider =
    FutureProvider.autoDispose<List<PosPriceListModel>>(retry: (_, _) => null, (
      ref,
    ) async {
      final allowed = ref.watch(
        authControllerProvider.select(
          (s) => s.session?.hasPermission(_applyPriceList) ?? false,
        ),
      );
      ref.watch(
        authControllerProvider.select((s) => s.session?.activeStore.id),
      );
      if (!allowed) return const [];
      return ref.watch(posRepositoryProvider).priceLists();
    });

final canCustomPriceProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(
    authControllerProvider.select(
      (s) => s.session?.hasPermission(_customPrice) ?? false,
    ),
  ),
);
