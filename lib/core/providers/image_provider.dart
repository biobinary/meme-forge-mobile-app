import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final selectedImageProvider = StateProvider.autoDispose<File?>((ref) => null);

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

class ImagePickerNotifier extends AsyncNotifier<void> {

  @override
  Future<void> build() async { }

  Future<File?> pickFromGallery(WidgetRef ref) async {
    return _pick(ref, ImageSource.gallery);
  }

  Future<File?> pickFromCamera(WidgetRef ref) async {
    return _pick(ref, ImageSource.camera);
  }

  Future<File?> _pick(WidgetRef ref, ImageSource source) async {
    state = const AsyncLoading();
    try {
      final picker = ref.read(imagePickerProvider);
      final XFile? xFile = await picker.pickImage(
        source: source,
        imageQuality: 85, 
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (xFile == null) {
        state = const AsyncData(null);
        return null;
      }

      final file = File(xFile.path);
      // Simpan ke shared state
      ref.read(selectedImageProvider.notifier).state = file;
      state = const AsyncData(null);
      return file;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final imagePickerNotifierProvider =
    AsyncNotifierProvider<ImagePickerNotifier, void>(
  ImagePickerNotifier.new,
);
