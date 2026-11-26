import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:casca_app/features/cash_registers/data/shift_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int shiftPageSize = 10;
const int shiftDetailPageSize = 20;

class ShiftPageController extends Notifier<int> {
  @override
  int build() {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    return 1;
  }

  void setPage(int page) => state = page;
}

final shiftListPageProvider =
    NotifierProvider.autoDispose<ShiftPageController, int>(
      ShiftPageController.new,
    );

final shiftListProvider =
    FutureProvider.autoDispose<PagedResponse<ShiftListItemModel>>(
      retry: (_, _) => null,
      (ref) => ref
          .watch(shiftRepositoryProvider)
          .getShifts(
            page: ref.watch(shiftListPageProvider),
            pageSize: shiftPageSize,
          ),
    );

class ShiftDetailPages {
  const ShiftDetailPages({this.movements = 1, this.sales = 1});

  final int movements;
  final int sales;
}

class ShiftDetailPagesController extends Notifier<ShiftDetailPages> {
  ShiftDetailPagesController(this.shiftId);

  final String shiftId;

  @override
  ShiftDetailPages build() => const ShiftDetailPages();

  void setMovements(int page) {
    state = ShiftDetailPages(movements: page, sales: state.sales);
  }

  void setSales(int page) {
    state = ShiftDetailPages(movements: state.movements, sales: page);
  }
}

final shiftDetailPagesProvider = NotifierProvider.autoDispose
    .family<ShiftDetailPagesController, ShiftDetailPages, String>(
      ShiftDetailPagesController.new,
    );

final shiftDetailProvider = FutureProvider.autoDispose
    .family<ShiftDetailModel, String>(retry: (_, _) => null, (ref, shiftId) {
      ref.watch(
        authControllerProvider.select((s) => s.session?.activeStore.id),
      );
      final pages = ref.watch(shiftDetailPagesProvider(shiftId));
      return ref
          .watch(shiftRepositoryProvider)
          .getShift(
            shiftId,
            movementsPage: pages.movements,
            salesPage: pages.sales,
            pageSize: shiftDetailPageSize,
          );
    });
