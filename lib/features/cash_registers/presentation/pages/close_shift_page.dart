import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/core/routing/unsaved_changes.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/domain/close_shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/current_shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/close_shift_steps.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/current_shift_skeleton.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_money_field.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_notice_view.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_step_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 560;

class CloseShiftPage extends ConsumerStatefulWidget {
  const CloseShiftPage({super.key});

  @override
  ConsumerState<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends ConsumerState<CloseShiftPage> {
  late final UnsavedChanges _unsavedChanges;
  final _countKey = GlobalKey<FormState>();
  final _withdrawalKey = GlobalKey<FormState>();
  final _counts = {
    for (final method in CountMethod.values) method: TextEditingController(),
  };
  final _notes = TextEditingController();
  final _withdrawn = TextEditingController();
  bool _withdrawing = false;

  bool _hasUnsavedChanges() {
    if (ref.read(closeShiftControllerProvider).value != null) return false;
    return _notes.text.isNotEmpty ||
        _counts.values.any((controller) => controller.text.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _unsavedChanges = ref.read(unsavedChangesProvider)
      ..watch(_hasUnsavedChanges);
  }

  @override
  void dispose() {
    _unsavedChanges.release(_hasUnsavedChanges);
    for (final controller in _counts.values) {
      controller.dispose();
    }
    _notes.dispose();
    _withdrawn.dispose();
    super.dispose();
  }

  void _leave() => context.go(AppRoutes.currentShift);

  void _back() {
    if (ref.read(closeShiftControllerProvider).isLoading) return;
    if (_withdrawing && ref.read(closeShiftControllerProvider).value == null) {
      setState(() => _withdrawing = false);
      return;
    }
    _leave();
  }

  ShiftCount _countOf(CurrentShiftModel shift) {
    final summary = shift.summary;
    return ShiftCount(
      expected: {
        CountMethod.cash: summary.expectedCash,
        CountMethod.creditCard: summary.creditCardSales,
        CountMethod.debitCard: summary.debitCardSales,
        CountMethod.transfer: summary.transferSales,
      },
      counted: {
        for (final entry in _counts.entries)
          entry.key: parseAmount(entry.value.text),
      },
    );
  }

  void _continue(ShiftCount count) {
    if (!_countKey.currentState!.validate() || !count.complete) return;
    setState(() {
      _withdrawn.text = amountText(count.countedCash);
      _withdrawing = true;
    });
  }

  void _confirm(CurrentShiftModel shift, ShiftCount count) {
    if (!_withdrawalKey.currentState!.validate()) return;
    final notes = _notes.text.trim();
    ref
        .read(closeShiftControllerProvider.notifier)
        .close(
          shift.shiftId,
          countedCash: count.countedCash,
          notes: notes.isEmpty ? null : notes,
          withdrawnAtClose: parseAmount(_withdrawn.text)!,
          paymentCounts: count.paymentCounts,
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final closing = ref.watch(closeShiftControllerProvider);
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final result = closing.value;

    if (result != null) {
      final canSeeDetail =
          session?.hasPermission('cashregister.shifts.view') ?? false;
      return _Scrollable(
        child: CloseResultView(
          result: result,
          onDone: _leave,
          onDetail: canSeeDetail
              ? () => context.go(AppRoutes.shiftDetailFor(result.shiftId))
              : null,
        ),
      );
    }

    final backButton = CascaButton(
      label: 'Volver al turno',
      variant: CascaButtonVariant.secondary,
      onPressed: _leave,
    );

    if (!(session?.hasPermission('cashregister.close') ?? false)) {
      return ShiftNoticeView(
        title: 'No tienes permiso para hacer el corte de caja.',
        actions: [backButton],
      );
    }

    final current = ref.watch(currentShiftProvider);
    if (!current.hasValue) {
      final error = current.error;
      if (error == null || current.isLoading) {
        return const CurrentShiftSkeleton();
      }
      return ShiftNoticeView(
        title: apiErrorMessage(
          error,
          'No fue posible obtener el turno actual.',
        ),
        actions: [
          CascaButton(
            label: 'Reintentar',
            onPressed: () => ref.invalidate(currentShiftProvider),
          ),
          backButton,
        ],
      );
    }

    final shift = current.value;
    if (shift == null) {
      return ShiftNoticeView(
        title: 'No hay un turno abierto',
        message: 'No queda ningún turno por cerrar.',
        actions: [backButton],
      );
    }

    return _form(context, shift, closing);
  }

  Widget _form(
    BuildContext context,
    CurrentShiftModel shift,
    AsyncValue<ClosedShiftModel?> closing,
  ) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final count = _countOf(shift);
    final saving = closing.isLoading;
    final error = closing.error;
    void refresh() => setState(() {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Scrollable(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space4,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CascaSpacing.space1,
                  children: [
                    Text('Corte de caja', style: textTheme.headlineMedium),
                    Text(
                      '${shift.cashRegisterName} · '
                      '${_withdrawing ? 'Retiro' : 'Recuento'}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                CascaStepProgress(
                  currentStep: _withdrawing ? 1 : 0,
                  totalSteps: 2,
                ),
                if (_withdrawing)
                  Form(
                    key: _withdrawalKey,
                    child: CloseWithdrawalStep(
                      countedCash: count.countedCash,
                      controller: _withdrawn,
                      enabled: !saving,
                      onChanged: refresh,
                    ),
                  )
                else
                  Form(
                    key: _countKey,
                    child: CloseCountStep(
                      count: count,
                      controllers: _counts,
                      notes: _notes,
                      onChanged: refresh,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            CascaSpacing.space4,
            CascaSpacing.space3,
            CascaSpacing.space4,
            CascaSpacing.space3 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space2,
            children: [
              if (error != null)
                Text(
                  apiErrorMessage(
                    error,
                    'No fue posible realizar el corte de caja.',
                    forbidden: 'No tienes permiso para cerrar este turno.',
                  ),
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CascaSpacing.space3,
                runSpacing: CascaSpacing.space2,
                children: [
                  CascaButton(
                    label: _withdrawing ? 'Volver' : 'Cancelar',
                    variant: CascaButtonVariant.secondary,
                    onPressed: saving ? null : _back,
                  ),
                  if (_withdrawing)
                    CascaButton(
                      label: 'Confirmar corte',
                      loading: saving,
                      onPressed: () => _confirm(shift, count),
                    )
                  else
                    CascaButton(
                      label: 'Continuar',
                      onPressed: () => _continue(count),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}
