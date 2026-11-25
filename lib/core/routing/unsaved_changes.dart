import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnsavedChanges {
  bool Function()? _check;

  bool get pending => _check?.call() ?? false;

  void watch(bool Function() check) => _check = check;

  void release(bool Function() check) {
    if (_check == check) _check = null;
  }
}

final unsavedChangesProvider = Provider<UnsavedChanges>(
  (ref) => UnsavedChanges(),
);
