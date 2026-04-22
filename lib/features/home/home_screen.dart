import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/image_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../editor/editor_screen.dart';

/// HomeScreen — halaman utama MemeMaker
/// Menampilkan dua CTA: Pilih dari Galeri dan Ambil Foto
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch state loading/error dari ImagePickerNotifier
    final pickerState = ref.watch(imagePickerNotifierProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    // Listener: navigasi ke EditorScreen setelah gambar berhasil dipilih
    ref.listen<File?>(selectedImageProvider, (previous, next) {
      if (next != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditorScreen(imageFile: next),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar.large(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MemeMaker',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              backgroundColor: colorScheme.surface,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  color: colorScheme.error,
                  onPressed: () {
                    ref.read(authServiceProvider).signOut();
                  },
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Body Content ─────────────────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Hero illustration / logo area
                    _HeroIllustration(colorScheme: colorScheme),

                    const SizedBox(height: 32),

                    userProfileAsync.when(
                      data: (profile) => Text(
                        'Halo, ${profile?['username'] ?? 'Meme Maker'}! 👋',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(height: 12),

                    // Headline
                    Text(
                      'Buat Meme Kamu Sendiri!',

                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih foto dari galeri atau ambil langsung\ndari kamera untuk mulai berkreasi.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // ── Error indicator ──
                    if (pickerState is AsyncError)
                      _ErrorBanner(
                        message: pickerState.error.toString(),
                        colorScheme: colorScheme,
                      ),

                    if (pickerState is AsyncError) const SizedBox(height: 16),

                    // ── CTA: Pilih dari Galeri ──
                    _PickerButton(
                      label: 'Pilih dari Galeri',
                      icon: Icons.photo_library_rounded,
                      isPrimary: true,
                      isLoading: pickerState is AsyncLoading,
                      onPressed: pickerState is AsyncLoading
                          ? null
                          : () => ref
                              .read(imagePickerNotifierProvider.notifier)
                              .pickFromGallery(ref),
                    ),

                    const SizedBox(height: 16),

                    // ── CTA: Ambil Foto ──
                    _PickerButton(
                      label: 'Ambil Foto',
                      icon: Icons.camera_alt_rounded,
                      isPrimary: false,
                      isLoading: false,
                      onPressed: pickerState is AsyncLoading
                          ? null
                          : () => ref
                              .read(imagePickerNotifierProvider.notifier)
                              .pickFromCamera(ref),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Illustration Widget ─────────────────────────────────────────────────

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          'assets/images/drake-hotline-bling-yes.png',
            width: 175,
            height: 175,
            fit: BoxFit.contain,
        ),
      ),
    );
  }
}


// ── Picker Button ────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = isLoading && isPrimary
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Text(label),
            ],
          );

    if (isPrimary) {
      return FilledButton(
        onPressed: onPressed,
        child: child,
      );
    } else {
      return FilledButton.tonal(
        onPressed: onPressed,
        child: child,
      );
    }
  }
}

// ── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.colorScheme,
  });

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memilih gambar. Pastikan izin kamera/galeri diberikan.',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
