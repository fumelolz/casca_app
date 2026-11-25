import 'dart:async';

import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  bool _chosen = false;

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  void select(ThemeMode mode) {
    _chosen = true;
    state = mode;
    unawaited(
      ref
          .read(preferencesStorageProvider)
          .write(PreferencesStorage.themeModeKey, mode.name),
    );
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(preferencesStorageProvider)
        .read(PreferencesStorage.themeModeKey);
    final mode = ThemeMode.values.asNameMap()[stored];
    if (!ref.mounted || _chosen || mode == null) return;
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
