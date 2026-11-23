import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

const double _barHeight = 4;
const Duration _transition = Duration(milliseconds: 250);

class CascaStepProgress extends StatelessWidget {
  const CascaStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(totalSteps > 0),
       assert(currentStep >= 0 && currentStep < totalSteps);

  final int currentStep;
  final int totalSteps;

  int get _percent => (((currentStep + 1) / totalSteps) * 100).round();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final infoStyle = textTheme.bodySmall?.copyWith(
      color: colors.textMuted,
      fontSize: CascaFontSize.xs,
    );

    return Semantics(
      label: 'Paso ${currentStep + 1} de $totalSteps',
      value: '$_percent% completado',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASO ${currentStep + 1} DE $totalSteps',
                style: infoStyle?.copyWith(
                  color: colors.info,
                  fontWeight: CascaFontWeight.semibold,
                  letterSpacing: 0.48,
                ),
              ),
              Text('$_percent% completado', style: infoStyle),
            ],
          ),
          const SizedBox(height: CascaSpacing.space2),
          Row(
            children: [
              for (var i = 0; i < totalSteps; i++) ...[
                if (i > 0) const SizedBox(width: CascaSpacing.space2),
                Expanded(
                  child: AnimatedContainer(
                    duration: _transition,
                    height: _barHeight,
                    decoration: BoxDecoration(
                      color: i <= currentStep ? colors.info : colors.border,
                      borderRadius: BorderRadius.circular(_barHeight),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
