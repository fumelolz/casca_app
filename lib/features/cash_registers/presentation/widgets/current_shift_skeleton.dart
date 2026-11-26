import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _titleWidth = 180;
const double _amountWidth = 160;

class CurrentShiftSkeleton extends StatelessWidget {
  const CurrentShiftSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: pagePadding(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space5,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CascaSkeleton(
              width: _titleWidth,
              height: CascaSpacing.space6,
            ),
          ),
          CascaCard(
            child: Column(
              spacing: CascaSpacing.space4,
              children: [
                CascaSkeleton(width: _amountWidth, height: CascaSpacing.space7),
                CascaSkeleton(height: CascaSpacing.space8),
              ],
            ),
          ),
          CascaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space4,
              children: [
                CascaSkeleton(),
                CascaSkeleton(),
                CascaSkeleton(),
                CascaSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
