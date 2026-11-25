import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:material_ui/material_ui.dart';

EdgeInsets pagePadding(BuildContext context) {
  final isMobile = MediaQuery.sizeOf(context).width <= mobileBreakpoint;
  return EdgeInsets.all(isMobile ? CascaSpacing.space5 : CascaSpacing.space7);
}
