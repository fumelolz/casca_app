import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/config/app_config.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

class CascaRemoteImage extends StatelessWidget {
  const CascaRemoteImage({
    super.key,
    required this.paths,
    this.fit = BoxFit.cover,
    this.iconSize = CascaSpacing.space5,
  });

  final List<String> paths;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) => _candidate(context, 0);

  Widget _candidate(BuildContext context, int index) {
    if (index >= paths.length) {
      return Center(
        child: CascaIcon(
          CascaIcons.cube,
          size: iconSize,
          color: context.casca.textMuted,
        ),
      );
    }

    return Image.network(
      '${AppConfig.apiUrl}${paths[index]}',
      fit: fit,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          _candidate(context, index + 1),
    );
  }
}
