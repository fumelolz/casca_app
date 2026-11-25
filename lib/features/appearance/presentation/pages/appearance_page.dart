import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/appearance/theme_mode_controller.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/features/appearance/presentation/widgets/theme_option_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 640;

const Map<ThemeMode, String> _themeLabels = {
  ThemeMode.light: 'Claro',
  ThemeMode.dark: 'Oscuro',
  ThemeMode.system: 'Sistema',
};

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final collapsed = ref.watch(sidebarProvider.select((s) => s.collapsed));
    final isMobile = MediaQuery.sizeOf(context).width <= mobileBreakpoint;
    void setCollapsed(bool value) =>
        ref.read(sidebarProvider.notifier).setCollapsed(value);

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CascaPageHeader(
                title: 'Apariencia',
                subtitle: 'Elige cómo se ve Casca en este dispositivo.',
              ),
              const SizedBox(height: CascaSpacing.space5),
              Text('Tema', style: textTheme.titleMedium),
              const SizedBox(height: CascaSpacing.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, entry)
                      in _themeLabels.entries.indexed) ...[
                    if (index > 0) const SizedBox(width: CascaSpacing.space3),
                    Expanded(
                      child: ThemeOptionCard(
                        label: entry.value,
                        mode: entry.key,
                        selected: themeMode == entry.key,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .select(entry.key),
                      ),
                    ),
                  ],
                ],
              ),
              if (!isMobile) ...[
                const SizedBox(height: CascaSpacing.space6),
                Text('Menú lateral', style: textTheme.titleMedium),
                const SizedBox(height: CascaSpacing.space2),
                Row(
                  children: [
                    CascaCheckbox(
                      value: collapsed,
                      semanticLabel: 'Mantener el menú contraído',
                      onChanged: setCollapsed,
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => setCollapsed(!collapsed),
                        child: Text(
                          'Mantener el menú contraído',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
