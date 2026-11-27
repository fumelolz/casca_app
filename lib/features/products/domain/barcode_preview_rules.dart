const List<int> _startPattern = [2, 1, 1, 2, 3, 2];
const List<int> _stopPattern = [2, 3, 3, 1, 1, 1, 2];

typedef BarcodePreviewBar = ({int x, int width});
typedef BarcodePreview = ({List<BarcodePreviewBar> bars, int totalWidth});

BarcodePreview buildBarcodePreview(String code) {
  final bars = <BarcodePreviewBar>[];
  var cursor = 0;

  void append(List<int> widths) {
    for (final (index, width) in widths.indexed) {
      if (index.isEven) bars.add((x: cursor, width: width));
      cursor += width;
    }
  }

  append(_startPattern);
  for (final seed in code.codeUnits) {
    final widths = List.filled(6, 1);
    for (var step = 0; step < 5; step++) {
      widths[(seed + step * 3) % 6]++;
    }
    append(widths);
  }
  append(_stopPattern);

  return (bars: bars, totalWidth: cursor);
}
