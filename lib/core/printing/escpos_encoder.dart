import 'dart:typed_data';

const int _bandRows = 128;
const int _blackThreshold = 128;
const List<int> _initialize = [0x1B, 0x40];
const List<int> _rasterImage = [0x1D, 0x76, 0x30, 0x00];
const List<int> _feedLines = [0x1B, 0x64, 0x04];
const List<int> _partialCut = [0x1D, 0x56, 0x42, 0x03];

Uint8List encodeEscPosImage(Uint8List rgba, {required int width}) {
  final height = rgba.length ~/ (width * 4);
  final bytesPerRow = width ~/ 8;
  final packed = Uint8List(bytesPerRow * height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < bytesPerRow * 8; x++) {
      final index = (y * width + x) * 4;
      final luminance =
          (rgba[index] * 77 + rgba[index + 1] * 150 + rgba[index + 2] * 29) >>
          8;
      if (luminance < _blackThreshold) {
        packed[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
      }
    }
  }

  final output = BytesBuilder()..add(_initialize);
  for (var start = 0; start < height; start += _bandRows) {
    final rows = (height - start).clamp(0, _bandRows);
    output
      ..add(_rasterImage)
      ..add([bytesPerRow & 0xFF, bytesPerRow >> 8, rows & 0xFF, rows >> 8])
      ..add(
        Uint8List.sublistView(
          packed,
          start * bytesPerRow,
          (start + rows) * bytesPerRow,
        ),
      );
  }
  output
    ..add(_feedLines)
    ..add(_partialCut);

  return output.takeBytes();
}
