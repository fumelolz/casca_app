import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/data/product_image_repository.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int maxSecondaryPhotos = 6;

class PhotoSlot {
  const PhotoSlot({
    required this.id,
    this.local,
    this.remote,
    this.uploaded = false,
  });

  final String id;
  final PickedPhoto? local;
  final ProductImageModel? remote;
  final bool uploaded;

  PhotoSlot markUploaded() =>
      PhotoSlot(id: id, local: local, remote: remote, uploaded: true);
}

class ProductPhotosState {
  const ProductPhotosState({
    this.main,
    this.secondary = const [],
    this.busy = false,
    this.loading = false,
    this.error,
  });

  final PhotoSlot? main;
  final List<PhotoSlot> secondary;
  final bool busy;
  final bool loading;
  final Object? error;

  int get freeSlots =>
      maxSecondaryPhotos - secondary.length + (main == null ? 1 : 0);

  ProductPhotosState copyWith({
    PhotoSlot? Function()? main,
    List<PhotoSlot>? secondary,
    bool? busy,
    bool? loading,
    Object? Function()? error,
  }) {
    return ProductPhotosState(
      main: main == null ? this.main : main(),
      secondary: secondary ?? this.secondary,
      busy: busy ?? this.busy,
      loading: loading ?? this.loading,
      error: error == null ? this.error : error(),
    );
  }
}

class ProductPhotosController extends Notifier<ProductPhotosState> {
  ProductPhotosController(this.productId);

  final String? productId;
  int _sequence = 0;

  bool get isEdit => productId != null;

  ProductImageRepository get _repository =>
      ref.read(productImageRepositoryProvider);

  @override
  ProductPhotosState build() {
    final id = productId;
    if (id == null) return const ProductPhotosState();

    final image = ref.read(productDetailProvider(id)).value?.image;
    Future.microtask(() => _loadGallery(id));
    return ProductPhotosState(
      main: image == null ? null : PhotoSlot(id: 'main', remote: image),
      loading: true,
    );
  }

  Future<void> add(List<PickedPhoto> photos) async {
    final id = productId;
    if (id == null) {
      for (final photo in photos.take(state.freeSlots)) {
        final slot = _slot(photo);
        state = state.main == null
            ? state.copyWith(main: () => slot)
            : state.copyWith(secondary: [...state.secondary, slot]);
      }
      return;
    }

    await _run(() async {
      for (final photo in photos.take(state.freeSlots)) {
        if (state.main == null) {
          await _repository.uploadMainImage(id, photo);
          if (!ref.mounted) return;
          final slot = _slot(photo);
          state = state.copyWith(main: () => slot);
        } else {
          final added = await _repository.addGalleryImage(id, photo);
          if (!ref.mounted) return;
          state = state.copyWith(
            secondary: [
              ...state.secondary,
              PhotoSlot(id: added.id, local: photo, remote: added.image),
            ],
          );
        }
      }
    });
  }

  Future<void> replaceMain(PickedPhoto photo) async {
    final id = productId;
    final slot = _slot(photo);
    if (id == null) {
      state = state.copyWith(main: () => slot);
      return;
    }
    await _run(() async {
      await _repository.uploadMainImage(id, photo);
      if (ref.mounted) state = state.copyWith(main: () => slot);
    });
  }

  Future<void> replace(String slotId, PickedPhoto photo) async {
    if (state.main?.id == slotId) return replaceMain(photo);

    final index = state.secondary.indexWhere((slot) => slot.id == slotId);
    if (index < 0) return;

    final id = productId;
    if (id == null) {
      final secondary = [...state.secondary];
      secondary[index] = _slot(photo);
      state = state.copyWith(secondary: secondary);
      return;
    }
    await _run(() => _replaceInGallery(id, index, photo));
  }

  Future<void> _replaceInGallery(
    String id,
    int index,
    PickedPhoto photo,
  ) async {
    final photos = [...state.secondary];
    final previous = photos[index];
    final full = photos.length >= maxSecondaryPhotos;

    Future<void> deletePrevious() async {
      await _repository.deleteGalleryImage(id, previous.id);
      photos.remove(previous);
    }

    try {
      if (full) await deletePrevious();
      final added = await _repository.addGalleryImage(id, photo);
      final replacement = PhotoSlot(
        id: added.id,
        local: photo,
        remote: added.image,
      );
      photos.add(replacement);
      if (!full) await deletePrevious();

      if (index == photos.length - 1) return;
      final ordered = [...photos]
        ..remove(replacement)
        ..insert(index, replacement);
      await _repository.reorderGallery(id, [
        for (final slot in ordered) slot.id,
      ]);
      photos
        ..clear()
        ..addAll(ordered);
    } finally {
      if (ref.mounted) state = state.copyWith(secondary: photos);
    }
  }

  Future<void> remove(String slotId) async {
    final id = productId;
    if (state.main?.id == slotId) {
      if (id != null) return;
      final rest = state.secondary;
      state = state.copyWith(
        main: () => rest.isEmpty ? null : rest.first,
        secondary: rest.skip(1).toList(),
      );
      return;
    }

    final remaining = state.secondary
        .where((slot) => slot.id != slotId)
        .toList();
    if (id == null) {
      state = state.copyWith(secondary: remaining);
      return;
    }
    await _run(() async {
      await _repository.deleteGalleryImage(id, slotId);
      if (ref.mounted) state = state.copyWith(secondary: remaining);
    });
  }

  void makeMain(String slotId) {
    final previous = state.main;
    final index = state.secondary.indexWhere((slot) => slot.id == slotId);
    if (isEdit || previous == null || index < 0) return;

    final secondary = [...state.secondary];
    final chosen = secondary[index];
    secondary[index] = previous;
    state = state.copyWith(main: () => chosen, secondary: secondary);
  }

  Future<void> reorder(int from, int to) async {
    if (state.busy) return;
    final previous = state.secondary;
    final reordered = [...previous];
    reordered.insert(to, reordered.removeAt(from));
    state = state.copyWith(secondary: reordered);

    final id = productId;
    if (id == null) return;
    await _run(
      () => _repository.reorderGallery(id, [
        for (final slot in reordered) slot.id,
      ]),
      onError: () => state = state.copyWith(secondary: previous),
    );
  }

  Future<bool> uploadPending(String newProductId) async {
    await _run(() async {
      final main = state.main;
      if (main?.local != null && !main!.uploaded) {
        await _repository.uploadMainImage(newProductId, main.local!);
        if (!ref.mounted) return;
        state = state.copyWith(main: main.markUploaded);
      }
      for (final slot in [...state.secondary]) {
        if (slot.local == null || slot.uploaded) continue;
        await _repository.addGalleryImage(newProductId, slot.local!);
        if (!ref.mounted) return;
        state = state.copyWith(
          secondary: [
            for (final other in state.secondary)
              other.id == slot.id ? other.markUploaded() : other,
          ],
        );
      }
    });
    return ref.mounted && state.error == null;
  }

  void report(Object error) => state = state.copyWith(error: () => error);

  PhotoSlot _slot(PickedPhoto photo) =>
      PhotoSlot(id: 'local-${_sequence++}', local: photo);

  Future<void> _loadGallery(String id) async {
    await _run(() async {
      final gallery = await _repository.getGallery(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        secondary: [
          for (final item in gallery)
            PhotoSlot(id: item.id, remote: item.image),
        ],
      );
    });
    if (ref.mounted) state = state.copyWith(loading: false);
  }

  Future<void> _run(
    Future<void> Function() action, {
    void Function()? onError,
  }) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: () => null);
    final keepAlive = ref.keepAlive();
    try {
      await action();
      if (ref.mounted && isEdit) ref.invalidate(productListProvider);
    } catch (error) {
      if (ref.mounted) {
        onError?.call();
        state = state.copyWith(error: () => error);
      }
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
      keepAlive.close();
    }
  }
}

final productPhotosProvider = NotifierProvider.autoDispose
    .family<ProductPhotosController, ProductPhotosState, String?>(
      ProductPhotosController.new,
    );
