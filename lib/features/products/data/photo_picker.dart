import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const double _maxPhotoSide = 1600;
const int _photoQuality = 85;

class PickedPhoto {
  const PickedPhoto({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class PhotoPicker {
  bool get hasCamera;

  Future<PickedPhoto?> takePhoto();

  Future<List<PickedPhoto>> pickFromGallery({required int limit});
}

class DevicePhotoPicker implements PhotoPicker {
  DevicePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get hasCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<PickedPhoto?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxPhotoSide,
      maxHeight: _maxPhotoSide,
      imageQuality: _photoQuality,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<List<PickedPhoto>> pickFromGallery({required int limit}) async {
    if (limit <= 0) return const [];
    final files = limit == 1
        ? [
            ?await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: _maxPhotoSide,
              maxHeight: _maxPhotoSide,
              imageQuality: _photoQuality,
            ),
          ]
        : await _picker.pickMultiImage(
            maxWidth: _maxPhotoSide,
            maxHeight: _maxPhotoSide,
            imageQuality: _photoQuality,
          );
    return Future.wait(files.take(limit).map(_read));
  }

  Future<PickedPhoto> _read(XFile file) async {
    return PickedPhoto(name: file.name, bytes: await file.readAsBytes());
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => DevicePhotoPicker());
