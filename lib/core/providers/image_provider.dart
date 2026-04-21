import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------------------
// Provider: menyimpan File? gambar yang dipilih (nullable)
// ---------------------------------------------------------------------------

/// StateProvider untuk menyimpan gambar yang dipilih.
/// Null berarti belum ada gambar yang dipilih.
final selectedImageProvider = StateProvider<File?>((ref) => null);

// ---------------------------------------------------------------------------
// Provider: ImagePickerService — singleton ImagePicker
// ---------------------------------------------------------------------------

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

// ---------------------------------------------------------------------------
// AsyncNotifier: menangani logika pick image secara terpusat
// ---------------------------------------------------------------------------

/// Notifier yang bertanggung jawab memilih gambar dari galeri atau kamera,
/// lalu menyimpannya ke [selectedImageProvider].
class ImagePickerNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Tidak ada inisialisasi awal
  }

  /// Membuka galeri foto
  Future<File?> pickFromGallery(WidgetRef ref) async {
    return _pick(ref, ImageSource.gallery);
  }

  /// Membuka kamera
  Future<File?> pickFromCamera(WidgetRef ref) async {
    return _pick(ref, ImageSource.camera);
  }

  Future<File?> _pick(WidgetRef ref, ImageSource source) async {
    state = const AsyncLoading();
    try {
      final picker = ref.read(imagePickerProvider);
      final XFile? xFile = await picker.pickImage(
        source: source,
        imageQuality: 85, // hemat memori, tetap tajam
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
