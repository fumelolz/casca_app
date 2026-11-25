import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:material_ui/material_ui.dart';

const double _filterWidth = 200;

class CascaFilterBar extends StatelessWidget {
  const CascaFilterBar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    this.filter,
  });

  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget? filter;

  @override
  Widget build(BuildContext context) {
    final search = CascaInput(
      hintText: searchHint,
      iconStart: CascaIcons.magnifyingGlass,
      clearable: true,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
    );
    final extra = filter;
    if (extra == null) return search;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < cascaTableCompactBreakpoint;
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            if (stacked) search else Expanded(child: search),
            const SizedBox.square(dimension: CascaSpacing.space3),
            if (stacked) extra else SizedBox(width: _filterWidth, child: extra),
          ],
        );
      },
    );
  }
}
