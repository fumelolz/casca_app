import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _titleWidth = 160;

class SaleDetailSkeleton extends StatelessWidget {
  const SaleDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const card = CascaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [CascaSkeleton(), CascaSkeleton(), CascaSkeleton()],
      ),
    );

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CascaSkeleton(
              width: _titleWidth,
              height: CascaSpacing.space6,
            ),
          ),
          card,
          card,
        ],
      ),
    );
  }
}
