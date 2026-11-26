import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/cash_registers/data/current_shift_repository.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/current_shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/cash_movement_modal.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/current_shift_cards.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/current_shift_skeleton.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/open_shift_modal.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_notice_view.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _wideBreakpoint = 900;

class CurrentShiftPage extends ConsumerWidget {
  const CurrentShiftPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentShiftProvider);
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canOpen = session?.hasPermission('cashregister.open') ?? false;

    if (current.isLoading && (!current.hasValue || current.isReloading)) {
      return const CurrentShiftSkeleton();
    }

    final error = current.error;
    if (error != null && !current.isLoading) {
      return ShiftNoticeView(
        title: apiErrorMessage(
          error,
          'No fue posible obtener el turno actual.',
          forbidden: 'No tienes permiso para ver el turno de caja.',
        ),
        actions: [
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(currentShiftProvider),
          ),
        ],
      );
    }

    final shift = current.value;
    if (shift == null) {
      return ShiftNoticeView(
        title: 'No hay un turno activo',
        message: canOpen
            ? 'Abre un turno para registrar ventas y movimientos de efectivo.'
            : 'No tienes permiso para abrir un turno. Pide a un administrador que te lo habilite.',
        actions: [
          if (canOpen)
            CascaButton(
              label: 'Abrir turno',
              size: CascaButtonSize.lg,
              onPressed: () => showCascaModal<void>(
                context: context,
                size: CascaModalSize.sm,
                builder: (_) => const OpenShiftModal(),
              ),
            ),
        ],
      );
    }

    return _OpenShift(
      shift: shift,
      canOperate: session?.hasPermission('cashregister.operate') ?? false,
      canClose: session?.hasPermission('cashregister.close') ?? false,
    );
  }
}

class _OpenShift extends StatelessWidget {
  const _OpenShift({
    required this.shift,
    required this.canOperate,
    required this.canClose,
  });

  final CurrentShiftModel shift;
  final bool canOperate;
  final bool canClose;

  Future<void> _move(BuildContext context, CashMovementType type) {
    return showCascaModal<void>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => CashMovementModal(shiftId: shift.shiftId, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final cash = CurrentCashCard(
      shift: shift,
      onDeposit: canOperate
          ? () => _move(context, CashMovementType.deposit)
          : null,
      onWithdraw: canOperate
          ? () => _move(context, CashMovementType.withdrawal)
          : null,
    );
    final sales = CurrentSalesCard(summary: shift.summary);
    final close = canClose
        ? CascaButton(
            label: 'Corte de caja',
            size: CascaButtonSize.lg,
            fullWidth: true,
            onPressed: () => context.go(AppRoutes.closeShift),
          )
        : null;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space5,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space3,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CascaSpacing.space1,
                  children: [
                    Text(
                      shift.cashRegisterName,
                      style: textTheme.headlineMedium,
                    ),
                    Text(
                      'Desde ${formatDateTime(shift.openedAt)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const CascaStatusChip(
                label: 'Turno abierto',
                tone: CascaChipTone.success,
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space4,
                  children: [cash, sales, ?close],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CascaSpacing.space5,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: CascaSpacing.space4,
                      children: [cash, ?close],
                    ),
                  ),
                  Expanded(child: sales),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
