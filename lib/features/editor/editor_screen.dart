import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/image_provider.dart';
import '../../core/providers/editor_provider.dart';
import 'crop_screen.dart';
import 'processing_screen.dart';

const List<String> _fontOptions = [
  'Anton',
  'Oswald',
  'Bebas Neue',
  'Black Ops One',
];

const List<Color> _colorOptions = [
  Colors.white,
  Color(0xFFFFD500), // Vibrant Yellow
  Color(0xFFF97316), // Orange
  Color(0xFFFF5555), // Red
  Color(0xFF00FF41), // Lime
  Color(0xFF4338CA), // Electric Indigo
  Colors.black,
];

TextStyle _getMemeTextStyle({
  required String font,
  double fontSize = 42,
  Color? color,
  Paint? foreground,
}) {
  final base = TextStyle(
    fontSize: fontSize,
    letterSpacing: 1.5,
    height: 1.1,
    color: foreground == null ? (color ?? Colors.white) : null,
    foreground: foreground,
  );
  switch (font) {
    case 'Oswald':
      return GoogleFonts.oswald(textStyle: base);
    case 'Bebas Neue':
      return GoogleFonts.bebasNeue(textStyle: base);
    case 'Black Ops One':
      return GoogleFonts.blackOpsOne(textStyle: base);
    case 'Anton':
    default:
      return GoogleFonts.anton(textStyle: base);
  }
}

TextStyle _getBaseFontStyle(String font) {
  switch (font) {
    case 'Oswald':
      return GoogleFonts.oswald();
    case 'Bebas Neue':
      return GoogleFonts.bebasNeue();
    case 'Black Ops One':
      return GoogleFonts.blackOpsOne();
    default:
      return GoogleFonts.anton();
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<_EditorCanvasState> _editorCanvasKey = GlobalKey<_EditorCanvasState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editorProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentImage = ref.watch(selectedImageProvider) ?? widget.imageFile;
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            height: 1.5,
            color: Colors.white12,
          ),
        ),
        title: Text(
          'Editor',
          style: GoogleFonts.anton(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () {
            ref.read(selectedImageProvider.notifier).state = null;
            ref.read(editorProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFD500),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () {
                _editorCanvasKey.currentState?.prepareForExport();
                Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, __, ___) => ProcessingScreen(
                      canvasKey: _canvasKey,
                      sourceFile: currentImage,
                    ),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ).then((_) {
                  _editorCanvasKey.currentState?.restoreAfterExport();
                });
              },
              child: Text(
                'Selesai',
                style: GoogleFonts.nunito(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _EditorCanvas(
              key: _editorCanvasKey,
              canvasKey: _canvasKey,
              imageFile: currentImage,
              editorState: editorState,
            ),
          ),

          _EditorToolbar(
            imageFile: currentImage,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _EditorCanvas extends ConsumerStatefulWidget {
  
  const _EditorCanvas({
    super.key,
    required this.canvasKey,
    required this.imageFile,
    required this.editorState,
  });

  final GlobalKey canvasKey;
  final File imageFile;
  final EditorState editorState;

  @override
  ConsumerState<_EditorCanvas> createState() => _EditorCanvasState();

}

class _EditorCanvasState extends ConsumerState<_EditorCanvas> {

  String? _activeOverlayId;

  final Map<String, GlobalKey> _stickerKeys = {};

  ColorFilter _getFilter(String filter) {
    switch (filter) {
      case 'Grayscale':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Sepia':
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Cool Blue':
        return const ColorFilter.matrix(<double>[
          0.8, 0.0, 0.0, 0, 0,
          0.0, 0.9, 0.0, 0, 0,
          0.0, 0.0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Normal':
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  bool _isDragging = false;
  bool _isNearTrash = false;
  bool _isExporting = false;
  final GlobalKey _trashKey = GlobalKey();

  void prepareForExport() {
    setState(() {
      _activeOverlayId = null;
      _isExporting = true;
    });
  }

  void restoreAfterExport() {
    if (mounted) {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _checkIfNearTrash(Offset globalPosition) {
    final trashBox = _trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (trashBox == null || !trashBox.hasSize) return;

    final trashPosition = trashBox.localToGlobal(Offset.zero);
    final trashSize = trashBox.size;

    // Expand detection area
    final trashRect = Rect.fromLTWH(
      trashPosition.dx - 20,
      trashPosition.dy - 20,
      trashSize.width + 40,
      trashSize.height + 40,
    );

    final isNear = trashRect.contains(globalPosition);
    if (isNear != _isNearTrash) {
      setState(() => _isNearTrash = isNear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTop = widget.editorState.topText?.isNotEmpty == true;
    final hasBottom = widget.editorState.bottomText?.isNotEmpty == true;

    // Ensure keys exist for every overlay and prune stale keys.
    final currentIds = widget.editorState.overlays.map((o) => o.id).toSet();
    _stickerKeys.removeWhere((id, _) => !currentIds.contains(id));
    for (final item in widget.editorState.overlays) {
      _stickerKeys.putIfAbsent(item.id, () => GlobalKey());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (_activeOverlayId != null) {
                  setState(() => _activeOverlayId = null);
                }
              },
              child: InteractiveViewer(
                panEnabled: false,
                minScale: 0.5,
                maxScale: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Center(
                    child: RepaintBoundary(
                      key: widget.canvasKey,
                      child: Stack(
                        clipBehavior: _isExporting ? Clip.hardEdge : Clip.none,
                        alignment: Alignment.center,
                        children: [
                            // ── Background Image & Texts ────────────────────────
                            ColorFiltered(
                              colorFilter: _getFilter(widget.editorState.activeFilter),
                              child: widget.editorState.croppedImageBytes != null
                                  ? Image.memory(
                                      widget.editorState.croppedImageBytes!,
                                    )
                                  : Image.file(
                                      widget.imageFile,
                                    ),
                            ),
                            if (hasTop)
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: GestureDetector(
                                  onLongPress: () => ref
                                      .read(editorProvider.notifier)
                                      .clearMemeText(MemeTextSlot.top),
                                  child: _MemeTextWidget(
                                    text: widget.editorState.topText!,
                                    font: widget.editorState.memeFont,
                                    color: widget.editorState.memeColor,
                                  ),
                                ),
                              ),
                            if (hasBottom)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: GestureDetector(
                                  onLongPress: () => ref
                                      .read(editorProvider.notifier)
                                      .clearMemeText(MemeTextSlot.bottom),
                                  child: _MemeTextWidget(
                                    text: widget.editorState.bottomText!,
                                    font: widget.editorState.memeFont,
                                    color: widget.editorState.memeColor,
                                  ),
                                ),
                              ),

                            // ── Stickers ────────────────────────────────────────
                            ...widget.editorState.overlays.map((item) {
                              return _DraggableSticker(
                                key: ValueKey(item.id),
                                stickerKey: _stickerKeys[item.id]!,
                                item: item,
                                isActive: _activeOverlayId == item.id,
                                onTap: () => setState(() => _activeOverlayId = item.id),
                                onDragStart: () => setState(() => _isDragging = true),
                                onDragUpdate: (globalPos) => _checkIfNearTrash(globalPos),
                                onDragEnd: (globalPos) {
                                  if (_isNearTrash) {
                                    ref.read(editorProvider.notifier).removeOverlay(item.id);
                                    setState(() => _activeOverlayId = null);
                                  }
                                  setState(() {
                                    _isDragging = false;
                                    _isNearTrash = false;
                                  });
                                },
                                onTransformChanged: () => setState(() {}),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Trash Bin UI ──────────────────────────────────────────────
            Positioned(
              bottom: 40,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isDragging ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _isDragging ? (_isNearTrash ? 1.3 : 1.0) : 0.8,
                  child: Container(
                    key: _trashKey,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isNearTrash ? const Color(0xFFFF5555) : const Color(0xFF18181B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        if (_isNearTrash)
                          const BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Icon(
                      _isNearTrash ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraggableSticker extends ConsumerStatefulWidget {
  const _DraggableSticker({
    super.key,
    required this.stickerKey,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onTransformChanged,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  /// Key attached to the visible sticker container
  final GlobalKey stickerKey;
  final OverlayItem item;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onTransformChanged;
  final VoidCallback onDragStart;
  final Function(Offset) onDragUpdate;
  final Function(Offset) onDragEnd;

  @override
  ConsumerState<_DraggableSticker> createState() => _DraggableStickerState();
}

class _DraggableStickerState extends ConsumerState<_DraggableSticker> {
  late Offset _localPosition;
  late double _localScale;
  late double _localRotation;

  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _localPosition = widget.item.position;
    _localScale = widget.item.scale;
    _localRotation = widget.item.rotation;
  }

  @override
  void didUpdateWidget(_DraggableSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.position != widget.item.position) {
      _localPosition = widget.item.position;
    }
    if (oldWidget.item.scale != widget.item.scale) {
      _localScale = widget.item.scale;
    }
    if (oldWidget.item.rotation != widget.item.rotation) {
      _localRotation = widget.item.rotation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invScale = 1.0 / _localScale;

    return Positioned(
      left: _localPosition.dx,
      top: _localPosition.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onScaleStart: (details) {
          widget.onTap();
          _baseScale = _localScale;
          _baseRotation = _localRotation;
          widget.onDragStart();
        },
        onScaleUpdate: (details) {
          setState(() {
            _localScale = (_baseScale * details.scale).clamp(0.2, 5.0);
            _localRotation = _baseRotation + details.rotation;
            _localPosition += details.focalPointDelta;
          });

          widget.onTransformChanged();

          final renderBox = widget.stickerKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final globalPos = renderBox.localToGlobal(
              Offset(renderBox.size.width / 2, renderBox.size.height / 2),
            );
            widget.onDragUpdate(globalPos);
          }
        },
        onScaleEnd: (details) {
          ref.read(editorProvider.notifier).updateOverlayTransform(
                widget.item.id,
                _localPosition,
                _localScale,
                _localRotation,
              );

          final renderBox = widget.stickerKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final globalPos = renderBox.localToGlobal(
              Offset(renderBox.size.width / 2, renderBox.size.height / 2),
            );
            widget.onDragEnd(globalPos);
          } else {
            // Fallback if renderBox is null
            widget.onDragEnd(Offset.zero);
          }
        },
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(_localScale)
            ..rotateZ(_localRotation),
          child: Container(
            padding: EdgeInsets.all(16 * invScale),
            color: Colors.transparent,
            child: Container(
              key: widget.stickerKey,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: widget.isActive
                  ? BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD500),
                        width: 3.0 * invScale,
                      ),
                      borderRadius: BorderRadius.circular(12 * invScale),
                      color: Colors.white.withValues(alpha: 0.1),
                    )
                  : BoxDecoration(
                      border: Border.all(
                        color: Colors.transparent,
                        width: 3.0 * invScale,
                      ),
                      borderRadius: BorderRadius.circular(12 * invScale),
                    ),
              child: Text(
                widget.item.content,
                style: TextStyle(fontSize: widget.item.size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemeTextWidget extends StatelessWidget {
  
  const _MemeTextWidget({
    required this.text,
    required this.font,
    required this.color,
  });

  final String text;
  final String font;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: _getMemeTextStyle(font: font, foreground: strokePaint),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: _getMemeTextStyle(font: font, color: color),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbar extends ConsumerWidget {
  const _EditorToolbar({
    required this.imageFile,
    required this.colorScheme,
  });

  final File imageFile;
  final ColorScheme colorScheme;

  void _showMemeTextDialog(BuildContext context, WidgetRef ref) {
    final s = ref.read(editorProvider);
    final topCtrl = TextEditingController(text: s.topText ?? '');
    final botCtrl = TextEditingController(text: s.bottomText ?? '');

    String selFont = s.memeFont;
    Color selColor = s.memeColor;

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
                            _MemeTextWidget(
                              text: topCtrl.text,
                              font: selFont,
                              color: selColor,
                            ),
                          if (topCtrl.text.isNotEmpty &&
                              botCtrl.text.isNotEmpty)
                            const SizedBox(height: 6),
                          if (botCtrl.text.isNotEmpty)
                            _MemeTextWidget(
                              text: botCtrl.text,
                              font: selFont,
                              color: selColor,
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

                    _TextSlotInput(
                      label: 'TEKS ATAS',
                      icon: Icons.vertical_align_top_rounded,
                      controller: topCtrl,
                      hint: 'Teks bagian atas...',
                      onChanged: () => setSheet(() {}),
                    ),
                    const SizedBox(height: 12),

                    // ── Teks Bawah ────────────────────────────────────────
                    _TextSlotInput(
                      label: 'TEKS BAWAH',
                      icon: Icons.vertical_align_bottom_rounded,
                      controller: botCtrl,
                      hint: 'Teks bagian bawah...',
                      onChanged: () => setSheet(() {}),
                    ),
                    const SizedBox(height: 18),

                    // ── Font Selector ─────────────────────────────────────
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
                        children: _fontOptions.map((font) {
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
                                  color: isSel
                                      ? const Color(0xFFFFD500)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFFFFD500)
                                        : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  font,
                                  style: _getBaseFontStyle(font).copyWith(
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
                      children: _colorOptions.map((c) {
                        final isSel = selColor == c;
                        final isDark =
                            c == Colors.black || c == const Color(0xFF4338CA);
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
                                  color: isSel
                                      ? const Color(0xFFFFD500)
                                      : Colors.white30,
                                  width: isSel ? 3 : 1.5,
                                ),
                              ),
                              child: isSel
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
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
                          notifier.setMemeText(
                              MemeTextSlot.bottom, botCtrl.text);
                          notifier.setMemeFont(selFont);
                          notifier.setMemeColor(selColor);
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

  void _showStickerSheet(BuildContext context, WidgetRef ref) {

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
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
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
                      final isSelected =
                          ref.watch(editorProvider).activeFilter == filter;
                      return ChoiceChip(
                        // Material 3 ignores TextStyle.color set inside the
                        // child widget; pass labelStyle directly so unselected
                        // chips remain readable against the dark background.
                        label: Text(filter),
                        labelStyle: GoogleFonts.nunito(
                          // Selected → black on yellow; Unselected → pure white
                          // (#FAFAFA would be 15:1 contrast on #18181B ≥ AA)
                          color: isSelected ? Colors.black : const Color(0xFFFAFAFA),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        showCheckmark: false,
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFD500),
                        // Unselected background lifted from near-invisible
                        // (white10 ≈ 10% opacity) to a clearly visible dark slab.
                        backgroundColor: const Color(0xFF2D2D30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFFD500)
                                : Colors.white54,
                            width: 1.5,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(editorProvider.notifier)
                                .setFilter(filter);
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

  Future<void> _openCropScreen(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(imageFile: imageFile),
      ),
    );
    if (result != null) {
      ref.read(editorProvider.notifier).applyCroppedImage(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _ToolbarItem(
              icon: Icons.crop_rounded,
              label: 'Crop',
              onTap: () => _openCropScreen(context, ref),
            ),
            _ToolbarItem(
              icon: Icons.text_fields_rounded,
              label: 'Teks',
              onTap: () => _showMemeTextDialog(context, ref),
            ),
            _ToolbarItem(
              icon: Icons.emoji_emotions_outlined,
              label: 'Stiker',
              onTap: () => _showStickerSheet(context, ref),
            ),
            _ToolbarItem(
              icon: Icons.photo_filter_rounded,
              label: 'Filter',
              onTap: () => _showFilterSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextSlotInput extends StatelessWidget {
  const _TextSlotInput({
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
        // Label row dengan icon
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              icon: const Icon(Icons.clear_rounded,
                  color: Colors.white38, size: 18),
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

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
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
                  color: highlighted
                      ? const Color(0xFFFFD500)
                      : Colors.white70,
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
