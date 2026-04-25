import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'result/result_notifier.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final Uint8List pngBytes;

  const ResultScreen({super.key, required this.pngBytes});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_onCaptionChanged);
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _captionController.dispose();
    super.dispose();
  }

  void _onCaptionChanged() {
    ref
        .read(resultProvider.notifier)
        .updateCaption(_captionController.text);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    await ref.read(resultProvider.notifier).upload(widget.pngBytes);

    if (!mounted) return;
    final state = ref.read(resultProvider);

    if (state.uploadStatus == ResultActionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meme berhasil diupload!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (state.errorMessage != null) {
      _showError(state.errorMessage!);
    }
  }

  Future<void> _handleDownload() async {
    final success =
        await ref.read(resultProvider.notifier).download(widget.pngBytes);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meme berhasil disimpan ke galeri!')),
      );
    } else {
      final msg = ref.read(resultProvider).errorMessage ??
          'Gagal menyimpan gambar.';
      _showError(msg);
    }
  }

  Future<void> _handleShare() async {
    await ref.read(resultProvider.notifier).share(widget.pngBytes);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(state, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MemePreview(pngBytes: widget.pngBytes, isDark: isDark),
            const SizedBox(height: 24),
            _CaptionField(
              controller: _captionController,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _ActionSection(
              isDark: isDark,
              onDownload: _handleDownload,
              onShare: _handleShare,
              isDownloading:
                  state.downloadStatus == ResultActionStatus.loading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ResultState state, bool isDark) {
    return AppBar(
      title: const Text('READY TO FORGE'),
      actions: [
        TextButton(
          onPressed: state.canUpload ? _handleUpload : null,
          child: state.isUploadLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: isDark ? const Color(0xFFFFD500) : Colors.black,
                  ),
                )
              : Text(
                  'UPLOAD',
                  style: GoogleFonts.anton(
                    fontSize: 18,
                    color: state.canUpload
                        ? (isDark ? const Color(0xFFFFD500) : Colors.black)
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _MemePreview extends StatelessWidget {
  const _MemePreview({required this.pngBytes, required this.isDark});

  final Uint8List pngBytes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black,
          width: 2,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(color: Colors.black, offset: Offset(6, 6)),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(pngBytes, fit: BoxFit.contain),
    );
  }
}

class _CaptionField extends StatelessWidget {
  const _CaptionField({required this.controller, required this.isDark});

  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAMBAHKAN CAPTION',
          style: GoogleFonts.anton(fontSize: 18, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Tulis sesuatu yang lucu...',
            hintStyle: GoogleFonts.nunito(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF27272A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.isDark,
    required this.onDownload,
    required this.onShare,
    required this.isDownloading,
  });

  final bool isDark;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BAGIKAN HASIL KARYAMU',
          style: GoogleFonts.anton(fontSize: 18, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: isDownloading ? '...' : 'DOWNLOAD',
                icon: Icons.download_rounded,
                onPressed: isDownloading ? null : onDownload,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'SHARE',
                icon: Icons.share_rounded,
                onPressed: onShare,
                isDark: isDark,
                color: const Color(0xFF4338CA),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;
  final Color? color;
  final Color? textColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDark,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFFFFD500),
        foregroundColor: textColor ?? Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
