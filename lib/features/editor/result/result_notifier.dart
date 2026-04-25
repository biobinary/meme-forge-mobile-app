import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/upload_service.dart';

enum ResultActionStatus { idle, loading, success, failure }

class ResultState {
  final String caption;
  final ResultActionStatus uploadStatus;
  final ResultActionStatus downloadStatus;
  final String? errorMessage;

  const ResultState({
    this.caption = '',
    this.uploadStatus = ResultActionStatus.idle,
    this.downloadStatus = ResultActionStatus.idle,
    this.errorMessage,
  });

  bool get isUploadLoading => uploadStatus == ResultActionStatus.loading;
  bool get canUpload =>
      caption.trim().isNotEmpty && uploadStatus != ResultActionStatus.loading;

  ResultState copyWith({
    String? caption,
    ResultActionStatus? uploadStatus,
    ResultActionStatus? downloadStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResultState(
      caption: caption ?? this.caption,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ResultNotifier extends StateNotifier<ResultState> {
  final UploadService _uploadService;

  ResultNotifier(this._uploadService) : super(const ResultState());

  void updateCaption(String value) {
    state = state.copyWith(caption: value, clearError: true);
  }

  Future<void> upload(Uint8List pngBytes) async {
    if (!state.canUpload) return;

    state = state.copyWith(
      uploadStatus: ResultActionStatus.loading,
      clearError: true,
    );

    try {
      await _uploadService.uploadMeme(
        pngBytes: pngBytes,
        caption: state.caption,
      );
      state = state.copyWith(uploadStatus: ResultActionStatus.success);
    } on StateError catch (e) {
      // User belum login
      state = state.copyWith(
        uploadStatus: ResultActionStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        uploadStatus: ResultActionStatus.failure,
        errorMessage: 'Gagal mengupload meme. Coba lagi.',
      );
    }
  }

  Future<bool> download(Uint8List pngBytes) async {
    state = state.copyWith(
      downloadStatus: ResultActionStatus.loading,
      clearError: true,
    );

    try {
      final success = await _uploadService.downloadToGallery(pngBytes);
      state = state.copyWith(
        downloadStatus:
            success ? ResultActionStatus.success : ResultActionStatus.failure,
        errorMessage: success ? null : 'Izin galeri diperlukan untuk menyimpan gambar.',
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        downloadStatus: ResultActionStatus.failure,
        errorMessage: 'Gagal menyimpan gambar.',
      );
      return false;
    }
  }

  // ---- Share ---------------------------------------------------------------

  Future<void> share(Uint8List pngBytes) async {
    try {
      await _uploadService.shareImage(
        pngBytes: pngBytes,
        shareText: state.caption.trim().isNotEmpty
            ? state.caption.trim()
            : 'Check out my meme from Meme Forge!',
      );
    } catch (_) {
      
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final uploadServiceProvider = Provider<UploadService>((_) => UploadService());

final resultProvider =
    StateNotifierProvider.autoDispose<ResultNotifier, ResultState>((ref) {
  return ResultNotifier(ref.watch(uploadServiceProvider));
});
