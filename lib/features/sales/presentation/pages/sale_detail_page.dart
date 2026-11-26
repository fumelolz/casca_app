import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/sales/presentation/providers/sales_providers.dart';
import 'package:casca_app/features/sales/presentation/widgets/sale_detail_cards.dart';
import 'package:casca_app/features/sales/presentation/widgets/sale_detail_skeleton.dart';
import 'package:casca_app/features/sales/presentation/widgets/sale_items_card.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class SaleDetailPage extends ConsumerWidget {
  const SaleDetailPage({super.key, required this.saleId, this.shiftId});

  final String saleId;
  final String? shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftId = this.shiftId;
    final backLabel = shiftId == null ? 'Volver a ventas' : 'Volver al turno';
    void back() => context.go(
      shiftId == null ? AppRoutes.sales : AppRoutes.shiftDetailFor(shiftId),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: _content(context, ref, backLabel, back),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    String backLabel,
    VoidCallback back,
  ) {
    final state = ref.watch(saleDetailProvider(saleId));
    final sale = state.value;
    final error = state.error;

    if (state.isLoading && (sale == null || state.isReloading)) {
      return const SaleDetailSkeleton();
    }

    if (sale == null || error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: CascaSpacing.space3,
            children: [
              Text(
                apiErrorMessage(
                  error ?? Object(),
                  'No fue posible cargar el detalle de la venta.',
                  forbidden: 'No tienes permiso para ver las ventas.',
                ),
                textAlign: TextAlign.center,
              ),
              CascaButton(
                label: 'Reintentar',
                variant: CascaButtonVariant.secondary,
                onPressed: () => ref.invalidate(saleDetailProvider(saleId)),
              ),
              CascaButton(
                label: backLabel,
                variant: CascaButtonVariant.text,
                onPressed: back,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          CascaPageHeader(
            title: 'Detalle de la venta',
            subtitle: 'Productos, pagos e importes.',
            action: CascaButton(
              label: backLabel,
              variant: CascaButtonVariant.secondary,
              onPressed: back,
            ),
          ),
          SaleHeaderCard(sale: sale),
          SaleItemsCard(sale: sale),
        ],
      ),
    );
  }
}
