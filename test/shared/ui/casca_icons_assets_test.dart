import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _declaredAssets() {
  final source = File('lib/shared/ui/casca_icon.dart').readAsStringSync();
  return RegExp(r"'(assets/icons/[a-z0-9-]+\.svg)'")
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toList();
}

void main() {
  final assets = _declaredAssets();

  test('hay iconos declarados', () {
    expect(assets, isNotEmpty);
  });

  test('cada icono declarado existe en versión outline', () {
    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('cada icono declarado existe también en versión rellena', () {
    for (final asset in assets) {
      final filled = asset.replaceFirst('.svg', '-fill.svg');
      expect(File(filled).existsSync(), isTrue, reason: filled);
    }
  });

  test('ningún archivo de icono queda sin declarar', () {
    final declared = {
      for (final asset in assets) ...[
        asset,
        asset.replaceFirst('.svg', '-fill.svg'),
      ],
    };
    final onDisk = Directory('assets/icons')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.svg'));

    expect(onDisk.where((path) => !declared.contains(path)), isEmpty);
  });

  test('se conserva la licencia de los iconos', () {
    expect(File('assets/icons/PHOSPHOR_LICENSE.txt').existsSync(), isTrue);
  });

  test('el logo de Casca conserva el SVG oficial y su licencia', () {
    final file = File('assets/brand/casca-bag.svg');

    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), contains('Font Awesome Free'));
  });
}
