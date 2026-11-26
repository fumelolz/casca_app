import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/cash_registers/domain/shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_detail_cards.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_detail_skeleton.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_detail_tables.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _twoColumnsBreakpoint = 760;

class ShiftDetailPage extends ConsumerWidget {
  const ShiftDetailPage({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.shiftHistory);
      },
      child: _content(context, ref),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftDetailProvider(shiftId));
    final pages = ref.watch(shiftDetailPagesProvider(shiftId));
    final controller = ref.read(shiftDetailPagesProvider(shiftId).notifier);
    final detail = state.value;
    final error = state.error;
    final canSeeSales = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('sale.view') ?? false,
      ),
    );

    void back() => context.go(AppRoutes.shiftHistory);

    if (detail == null) {
      if (error == null || state.isLoading) return const ShiftDetailSkeleton();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CascaSpacing.space3,
          children: [
            Text(
              apiErrorMessage(
                error,
                'No fue posible obtener el detalle del turno.',
                forbidden: 'No tienes permiso para ver los turnos.',
              ),
              textAlign: TextAlign.center,
            ),
            CascaButton(
              label: 'Reintentar',
              variant: CascaButtonVariant.secondary,
              onPressed: () => ref.invalidate(shiftDetailProvider(shiftId)),
            ),
            CascaButton(
              label: 'Volver al historial',
              variant: CascaButtonVariant.text,
              onPressed: back,
            ),
          ],
        ),
      );
    }

    final counts = closedShiftCounts(detail);
    final sales = ShiftSalesCard(summary: detail.summary);
    final cash = ShiftCashCard(detail: detail);

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          CascaPageHeader(
            title: 'Detalle del turno',
            subtitle: 'Ventas, efectivo y movimientos del turno.',
            action: CascaButton(
              label: 'Volver al historial',
              variant: CascaButtonVariant.secondary,
              onPressed: back,
            ),
          ),
          if (error != null && !state.isLoading)
            Text(
              apiErrorMessage(error, 'No fue posible actualizar el detalle.'),
            ),
          ShiftHeaderCard(shift: detail.shift),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _twoColumnsBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space4,
                  children: [sales, cash],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CascaSpacing.space4,
                children: [
                  Expanded(child: sales),
                  Expanded(child: cash),
                ],
              );
            },
          ),
          if (counts.isNotEmpty) ShiftCountsCard(rows: counts),
          ShiftMovementsTable(
            movements: detail.movements.items,
            page: pages.movements,
            totalItems: detail.movements.totalCount,
            loading: state.isLoading,
            onPageChanged: controller.setMovements,
          ),
          ShiftSalesTable(
            sales: detail.sales.items,
            page: pages.sales,
            totalItems: detail.sales.totalCount,
            loading: state.isLoading,
            onPageChanged: controller.setSales,
            onSaleTap: canSeeSales
                ? (sale) => context.go(
                    AppRoutes.saleDetailFor(sale.id, shiftId: shiftId),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
