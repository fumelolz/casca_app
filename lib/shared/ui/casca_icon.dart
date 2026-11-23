import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

abstract final class CascaIcons {
  static const String bagShopping = 'assets/icons/bag-shopping.svg';
  static const String envelope = 'assets/icons/envelope.svg';
  static const String eye = 'assets/icons/eye.svg';
  static const String eyeSlash = 'assets/icons/eye-slash.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String xmark = 'assets/icons/xmark.svg';
}

class CascaIcon extends StatelessWidget {
  const CascaIcon(this.asset, {super.key, this.size = 16, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? context.casca.textSecondary;

    return SvgPicture.asset(
      asset,
      height: size,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
