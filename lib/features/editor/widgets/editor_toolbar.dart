import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/editor_provider.dart';
import '../../../core/services/background_service.dart';
import '../utils/editor_utils.dart';
import '../crop_screen.dart';
import 'meme_text_widget.dart';

const _kAiSuggestionKey = kAiSuggestionKey;
const _kAiErrorKey = kAiErrorKey;

class EditorToolbar extends ConsumerStatefulWidget {
  const EditorToolbar({
    super.key,
    required this.imageFile,
    required this.colorScheme,
  });

  final File imageFile;
  final ColorScheme colorScheme;

  @override
  ConsumerState<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends ConsumerState<EditorToolbar> {
  /// Set to false in dispose() to abort the AI polling loop safely.
  bool _isPolling = false;

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  void _showMemeTextDialog(BuildContext context) {
    final s = ref.read(editorProvider);
    final topCtrl = TextEditingController(text: s.topText ?? '');
    final botCtrl = TextEditingController(text: s.bottomText ?? '');

    String selFont = s.memeFont;
    Color selColor = s.memeColor;
    double selFontSize = s.memeFontSize;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TEKS MEME',
                      style: GoogleFonts.anton(
                        textStyle: const TextStyle(
                          color: Color(0xFFFFD500),
                          fontSize: 20,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      'Tekan lama teks di canvas untuk menghapus.',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 72),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (topCtrl.text.isNotEmpty)
                            MemeTextWidget(
                              text: topCtrl.text,
                              font: selFont,
                              color: selColor,
                              fontSize: selFontSize * 0.7, // Skala kecil untuk preview
                            ),
                          if (topCtrl.text.isNotEmpty && botCtrl.text.isNotEmpty)
                            const SizedBox(height: 6),
                          if (botCtrl.text.isNotEmpty)
                            MemeTextWidget(
                              text: botCtrl.text,
                              font: selFont,
                              color: selColor,
                              fontSize: selFontSize * 0.7, // Skala kecil untuk preview
                            ),
                          if (topCtrl.text.isEmpty && botCtrl.text.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Preview meme text...',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextSlotInput(
                      label: 'TEKS ATAS',
                      icon: Icons.vertical_align_top_rounded,
                      controller: topCtrl,
                      hint: 'Teks bagian atas...',
                      onChanged: () => setSheet(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextSlotInput(
                      label: 'TEKS BAWAH',
                      icon: Icons.vertical_align_bottom_rounded,
                      controller: botCtrl,
                      hint: 'Teks bagian bawah...',
                      onChanged: () => setSheet(() {}),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'FONT',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: EditorUtils.fontOptions.map((font) {
                          final isSel = selFont == font;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setSheet(() => selFont = font),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFFFD500) : Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFFFFD500) : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  font,
                                  style: EditorUtils.getBaseFontStyle(font).copyWith(
                                    fontSize: 14,
                                    color: isSel ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'WARNA TEKS',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: EditorUtils.colorOptions.map((c) {
                        final isSel = selColor == c;
                        final isDark = c == Colors.black || c == const Color(0xFF4338CA);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setSheet(() => selColor = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? const Color(0xFFFFD500) : Colors.white30,
                                  width: isSel ? 3 : 1.5,
                                ),
                              ),
                              child: isSel
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: isDark ? Colors.white : Colors.black,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'UKURAN FONT',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.text_fields_rounded, color: Colors.white38, size: 16),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFFFFD500),
                              inactiveTrackColor: Colors.white10,
                              thumbColor: const Color(0xFFFFD500),
                              overlayColor: const Color(0xFFFFD500).withValues(alpha: 0.2),
                              valueIndicatorColor: const Color(0xFFFFD500),
                              valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            child: Slider(
                              value: selFontSize,
                              min: EditorUtils.minFontSize,
                              max: EditorUtils.maxFontSize,
                              divisions: (EditorUtils.maxFontSize - EditorUtils.minFontSize).toInt(),
                              label: selFontSize.round().toString(),
                              onChanged: (val) => setSheet(() => selFontSize = val),
                            ),
                          ),
                        ),
                        Text(
                          selFontSize.round().toString(),
                          style: GoogleFonts.anton(
                            color: const Color(0xFFFFD500),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD500),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final notifier = ref.read(editorProvider.notifier);
                          notifier.setMemeText(MemeTextSlot.top, topCtrl.text);
                          notifier.setMemeText(MemeTextSlot.bottom, botCtrl.text);
                          notifier.setMemeFont(selFont);
                          notifier.setMemeColor(selColor);
                          notifier.setMemeFontSize(selFontSize);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Terapkan',
                          style: GoogleFonts.nunito(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStickerSheet(BuildContext context) {
    const emojis = [
      '😂', '😎', '🔥', '💀', '💯', '🤔', '🤡', '👀',
      '😭', '🫡', '🗿', '✨',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Stiker',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(editorProvider.notifier).addOverlay(
                            OverlayItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              type: OverlayType.sticker,
                              content: emojis[index],
                              position: const Offset(120, 200),
                              color: Colors.white,
                              size: 64,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    const filters = ['Normal', 'Grayscale', 'Sepia', 'Cool Blue'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Filter',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: filters.map((filter) {
                  return Consumer(
                    builder: (context, ref, _) {
                      final isSelected = ref.watch(editorProvider).activeFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        labelStyle: GoogleFonts.nunito(
                          color: isSelected ? Colors.black : const Color(0xFFFAFAFA),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        showCheckmark: false,
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFD500),
                        backgroundColor: const Color(0xFF2D2D30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFFD500) : Colors.white54,
                            width: 1.5,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(editorProvider.notifier).setFilter(filter);
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCropScreen(BuildContext context) async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(imageFile: widget.imageFile),
      ),
    );
    if (result != null) {
      ref.read(editorProvider.notifier).applyCroppedImage(result);
    }
  }

  Future<void> _autoEditWithAI(BuildContext context) async {
    // Prevent double-trigger if already polling
    if (_isPolling) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    _isPolling = true;

    try {
      ref.read(aiProcessingProvider.notifier).state = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAiSuggestionKey);
      await prefs.remove(_kAiErrorKey);

      BackgroundService.scheduleAITask(widget.imageFile.path, user.uid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI sedang bekerja di background... 🧠'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF2D2D30),
          ),
        );
      }

      int attempts = 0;
      const maxAttempts = 60;

      while (attempts < maxAttempts &&
          _isPolling &&
          mounted &&
          ref.read(aiProcessingProvider)) {
        await Future.delayed(const Duration(seconds: 1));

        // Re-check after await — widget may have been disposed during sleep
        if (!mounted || !_isPolling) break;

        await prefs.reload();

        // ── Check for error first ──
        final errorStr = prefs.getString(_kAiErrorKey);
        if (errorStr != null) {
          await prefs.remove(_kAiErrorKey);
          if (!mounted || !_isPolling) break;

          ref.read(aiProcessingProvider.notifier).state = false;

          if (context.mounted) {
            _showAiErrorDialog(context, errorStr);
          }
          break;
        }

        final resultStr = prefs.getString(_kAiSuggestionKey);
        if (resultStr != null) {
          await prefs.remove(_kAiSuggestionKey);
          if (!mounted || !_isPolling) break;

          final Map<String, dynamic> json = jsonDecode(resultStr) as Map<String, dynamic>;

          final resultImagePath = json['imagePath'] as String?;
          if (resultImagePath != null && resultImagePath != widget.imageFile.path) {
            attempts++;
            continue;
          }

          ref.read(aiProcessingProvider.notifier).state = false;
          ref.read(editorProvider.notifier).applyAIJson(json);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI telah mengedit meme kamu! ✨'),
                backgroundColor: Color(0xFFFFD500),
              ),
            );
          }
          break;
        }

        attempts++;
      }

      if (mounted &&
          _isPolling &&
          attempts >= maxAttempts &&
          ref.read(aiProcessingProvider)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI butuh waktu lebih lama. Cek notifikasi nanti ya! 🔔'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isPolling = false;
      if (mounted) {
        ref.read(aiProcessingProvider.notifier).state = false;
      }
    }
  }

  void _showAiErrorDialog(BuildContext context, String errorMessage) {
    final isQuotaError = errorMessage.contains('batas') || errorMessage.contains('limit');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              isQuotaError ? Icons.hourglass_empty_rounded : Icons.error_outline_rounded,
              color: const Color(0xFFFFD500),
            ),
            const SizedBox(width: 10),
            Text(
              isQuotaError ? 'Kuota Habis' : 'AI Gagal',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFFD500), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          border: Border(
            top: BorderSide(color: Colors.white10, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ToolbarItem(
              icon: Icons.crop_rounded,
              label: 'Crop',
              onTap: () => _openCropScreen(context),
            ),
            ToolbarItem(
              icon: Icons.text_fields_rounded,
              label: 'Teks',
              onTap: () => _showMemeTextDialog(context),
            ),
            ToolbarItem(
              icon: Icons.emoji_emotions_outlined,
              label: 'Stiker',
              onTap: () => _showStickerSheet(context),
            ),
            ToolbarItem(
              icon: Icons.photo_filter_rounded,
              label: 'Filter',
              onTap: () => _showFilterSheet(context),
            ),
            ToolbarItem(
              icon: Icons.auto_fix_high_rounded,
              label: 'Magic AI',
              highlighted: true,
              onTap: () => _autoEditWithAI(context),
            ),
          ],
        ),
      ),
    );
  }
}

class TextSlotInput extends StatelessWidget {
  const TextSlotInput({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: GoogleFonts.anton(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFFD500),
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
              onPressed: () {
                controller.clear();
                onChanged();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ToolbarItem extends StatelessWidget {
  const ToolbarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? const Color(0xFFFFD500) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: highlighted ? const Color(0xFFFFD500) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
