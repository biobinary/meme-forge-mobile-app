import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/image_provider.dart';

/// EditorScreen — halaman editor meme (Tahap 1: hanya menampilkan gambar)
/// Menerima imageFile langsung sebagai parameter konstruktor,
/// dan juga bisa watch dari selectedImageProvider.
class EditorScreen extends ConsumerWidget {
  const EditorScreen({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Bisa juga langsung watch dari provider (untuk sinkronisasi state global)
    final currentImage = ref.watch(selectedImageProvider) ?? imageFile;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Editor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () {
            // Reset gambar saat kembali ke HomeScreen
            ref.read(selectedImageProvider.notifier).state = null;
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Placeholder action untuk Tahap 2 (simpan/share)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'Opsi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur akan hadir di Tahap 2!'),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Image Viewer (hero) ─────────────────────────────────────────
          Expanded(
            child: _ImageViewer(imageFile: currentImage),
          ),

          // ── Bottom Toolbar (placeholder) ──────────────────────────────
          _EditorToolbar(colorScheme: colorScheme),
        ],
      ),
    );
  }
}

// ── Image Viewer ──────────────────────────────────────────────────────────────

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'Gagal memuat gambar',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Editor Toolbar (placeholder untuk Tahap 2) ────────────────────────────────

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        color: const Color(0xFF1A1A2E),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ToolbarItem(
              icon: Icons.text_fields_rounded,
              label: 'Teks',
              color: colorScheme.primary,
            ),
            _ToolbarItem(
              icon: Icons.emoji_emotions_outlined,
              label: 'Stiker',
              color: colorScheme.secondary,
            ),
            _ToolbarItem(
              icon: Icons.crop_rounded,
              label: 'Crop',
              color: colorScheme.tertiary,
            ),
            _ToolbarItem(
              icon: Icons.save_alt_rounded,
              label: 'Simpan',
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label — segera hadir di Tahap 2!')),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
