import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_sale_provider.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _View { select, single, split }

enum _Tone { blue, green, yellow, indigo, orange, teal }

class _Method {
  const _Method({
    required this.method,
    required this.label,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final PaymentMethod method;
  final String label;
  final String description;
  final String icon;
  final _Tone tone;
}

const _Method _cash = _Method(
  method: PaymentMethod.cash,
  label: 'Efectivo',
  description: 'Registrar compra en efectivo',
  icon: CascaIcons.money,
  tone: _Tone.blue,
);

const List<_Method> _referenceMethods = [
  _Method(
    method: PaymentMethod.creditCard,
    label: 'Tarjeta de Crédito',
    description: 'Registrar compra con tarjeta de crédito',
    icon: CascaIcons.creditCard,
    tone: _Tone.yellow,
  ),
  _Method(
    method: PaymentMethod.debitCard,
    label: 'Tarjeta de Débito',
    description: 'Registrar compra con tarjeta de débito',
    icon: CascaIcons.creditCard,
    tone: _Tone.indigo,
  ),
  _Method(
    method: PaymentMethod.transfer,
    label: 'Transferencia',
    description: 'Registrar compra con transferencia',
    icon: CascaIcons.arrowRight,
    tone: _Tone.orange,
  ),
];

const double _amountWidth = 140;
const double _besideWidth = 400;
const int _inputFlex = 4;
const int _buttonFlex = 3;

String _money(int cents) => formatMoney(cents / 100);

String _shortMoney(int cents) => _money(cents).replaceFirst('.00', '');

class _CashRow extends StatelessWidget {
  const _CashRow({required this.input, required this.buttons});

  final Widget input;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final beside = constraints.maxWidth >= _besideWidth;
        final row = Row(
          spacing: CascaSpacing.space2,
          children: [
            if (beside) Expanded(flex: _inputFlex, child: input),
            for (final button in buttons)
              Expanded(flex: _buttonFlex, child: button),
          ],
        );

        if (beside) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space2,
          children: [input, row],
        );
      },
    );
  }
}

class PosPaymentModal extends ConsumerStatefulWidget {
  const PosPaymentModal({super.key, required this.totalCents});

  final int totalCents;

  @override
  ConsumerState<PosPaymentModal> createState() => _PosPaymentModalState();
}

class _PosPaymentModalState extends ConsumerState<PosPaymentModal> {
  final _received = TextEditingController();
  final _split = {
    for (final method in PaymentMethod.values) method: TextEditingController(),
  };
  _View _view = _View.select;
  _Method _single = _referenceMethods.first;

  int get _total => widget.totalCents;

  @override
  void dispose() {
    _received.dispose();
    for (final controller in _split.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _pay(Payment? payment) {
    if (payment != null) ref.read(saleProvider.notifier).submit(payment);
  }

  void _show(_View view) {
    for (final controller in _split.values) {
      controller.clear();
    }
    setState(() => _view = view);
  }

  Widget _amountInput(
    TextEditingController controller,
    String label, {
    required bool enabled,
    VoidCallback? onSubmitted,
  }) {
    return Semantics(
      label: label,
      child: CascaInput(
        key: Key('payment-input-$label'),
        controller: controller,
        enabled: enabled,
        hintText: '0',
        prefixText: r'$',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          TextInputFormatter.withFunction((_, value) {
            final text = sanitizeMoneyText(value.text);
            return TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          }),
        ],
        onChanged: (_) => setState(() {}),
        onFieldSubmitted: (_) => onSubmitted?.call(),
      ),
    );
  }

  List<Widget> _selectView(bool submitting) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final received = parseMoneyToCents(_received.text);
    final payment = cashPayment(_total, _received.text);

    return [
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space3,
          children: [
            const _MethodTitle(_cash),
            _CashRow(
              input: _amountInput(
                _received,
                'Efectivo recibido',
                enabled: !submitting,
                onSubmitted: () => _pay(cashPayment(_total, _received.text)),
              ),
              buttons: [
                if (_received.text.isEmpty)
                  for (final amount in quickCashAmounts(_total))
                    CascaButton(
                      label: _shortMoney(amount),
                      fullWidth: true,
                      onPressed: submitting
                          ? null
                          : () => setState(
                              () => _received.text = centsToText(amount),
                            ),
                    )
                else
                  CascaButton(
                    label: 'Recibir',
                    fullWidth: true,
                    loading: submitting,
                    onPressed: payment == null ? null : () => _pay(payment),
                  ),
              ],
            ),
            if (received != null && received < _total)
              Text(
                'Faltan ${_money(_total - received)}',
                style: textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
          ],
        ),
      ),
      _Card(
        padded: false,
        child: Column(
          children: [
            const _Row(
              icon: CascaIcons.bank,
              tone: _Tone.green,
              label: 'A Crédito',
              trailing: _Soon(),
            ),
            for (final method in _referenceMethods)
              _Row(
                icon: method.icon,
                tone: method.tone,
                label: method.label,
                chevron: true,
                onTap: submitting
                    ? null
                    : () {
                        _single = method;
                        _show(_View.single);
                      },
              ),
          ],
        ),
      ),
      _Card(
        padded: false,
        child: _Row(
          icon: CascaIcons.shuffle,
          tone: _Tone.teal,
          label: 'Usar Múltiples Métodos',
          chevron: true,
          onTap: submitting ? null : () => _show(_View.split),
        ),
      ),
    ];
  }

  List<Widget> _singleView(bool submitting) {
    return [
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space3,
          children: [
            _MethodTitle(_single),
            Text(_single.description),
            CascaButton(
              label: submitting
                  ? 'Registrando venta...'
                  : 'Cobrar ${_money(_total)}',
              size: CascaButtonSize.lg,
              fullWidth: true,
              loading: submitting,
              onPressed: () => _pay(singlePayment(_single.method, _total)),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _splitView(bool submitting) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final evaluation = evaluateSplit(_total, {
      for (final entry in _split.entries) entry.key: entry.value.text,
    });
    final touched = _split.values.any((c) => c.text.isNotEmpty);
    final short = evaluation.shortfallCents > 0;

    return [
      if (touched)
        Text(
          evaluation.exceedsTotal
              ? 'Los pagos sin efectivo superan el total'
              : short
              ? 'Faltan ${_money(evaluation.shortfallCents)}'
              : 'Cambio ${_money(evaluation.changeCents)}',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: short || evaluation.exceedsTotal
                ? colors.danger
                : colors.success,
          ),
        ),
      _Card(
        padded: false,
        child: Column(
          children: [
            const _Row(
              icon: CascaIcons.bank,
              tone: _Tone.green,
              label: 'A Crédito',
              trailing: _Soon(),
            ),
            for (final method in [_cash, ..._referenceMethods])
              _Row(
                icon: method.icon,
                tone: method.tone,
                label: method.label,
                trailing: SizedBox(
                  width: _amountWidth,
                  child: _amountInput(
                    _split[method.method]!,
                    method.label,
                    enabled: !submitting,
                  ),
                ),
              ),
          ],
        ),
      ),
      CascaButton(
        label: submitting ? 'Registrando venta...' : 'Cobrar',
        size: CascaButtonSize.lg,
        fullWidth: true,
        loading: submitting,
        onPressed: evaluation.payment == null
            ? null
            : () => _pay(evaluation.payment),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final sale = ref.watch(saleProvider);
    final submitting = sale.submitting;
    final failure = sale.failure;

    ref.listen(saleProvider, (previous, next) {
      final rejected = next.failure?.lineErrors.isNotEmpty ?? false;
      if (next.completed != null || rejected) {
        Navigator.of(context).pop(next.completed);
      }
    });

    return CascaModal(
      title: 'Registrar Venta',
      showCloseButton: !submitting,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          Column(
            children: [
              Text(
                'Total a cobrar',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                _money(_total),
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: CascaFontSize.xxl,
                  fontWeight: CascaFontWeight.semibold,
                ),
              ),
            ],
          ),
          if (failure != null)
            Text(
              failure.message,
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          if (_view != _View.select)
            Align(
              alignment: Alignment.centerLeft,
              child: CascaButton(
                label: 'Volver',
                variant: CascaButtonVariant.text,
                onPressed: submitting ? null : () => _show(_View.select),
              ),
            ),
          ...switch (_view) {
            _View.select => _selectView(submitting),
            _View.single => _singleView(submitting),
            _View.split => _splitView(submitting),
          },
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padded = true});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padded ? const EdgeInsets.all(CascaSpacing.space4) : null,
      decoration: BoxDecoration(
        borderRadius: CascaRadius.md,
        border: Border.all(color: context.casca.border),
      ),
      child: child,
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon(this.icon, this.tone);

  final String icon;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final (background, foreground) = switch (tone) {
      _Tone.blue => (colors.primarySoft, colors.primary),
      _Tone.green => (colors.successSoft, colors.success),
      _Tone.yellow => (colors.warningSoft, colors.warning),
      _Tone.indigo => (colors.infoSoft, colors.info),
      _Tone.orange => (colors.dangerSoft, colors.danger),
      _Tone.teal => (colors.backgroundHover, colors.text),
    };

    return Container(
      width: CascaSpacing.space8,
      height: CascaSpacing.space8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: CascaRadius.sm,
      ),
      child: CascaIcon(icon, size: CascaSpacing.space5, color: foreground),
    );
  }
}

class _MethodTitle extends StatelessWidget {
  const _MethodTitle(this.method);

  final _Method method;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: CascaSpacing.space3,
      children: [
        _MethodIcon(method.icon, method.tone),
        Text(method.label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tone,
    required this.label,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  final String icon;
  final _Tone tone;
  final String label;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return InkWell(
      onTap: onTap,
      borderRadius: CascaRadius.md,
      child: Padding(
        padding: const EdgeInsets.all(CascaSpacing.space3),
        child: Row(
          spacing: CascaSpacing.space3,
          children: [
            _MethodIcon(icon, tone),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            ?trailing,
            if (chevron)
              CascaIcon(
                CascaIcons.chevronRight,
                size: CascaSpacing.space4,
                color: context.casca.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Próximamente',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.casca.textMuted),
    );
  }
}
