import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/editor_provider.dart';
import '../utils/editor_utils.dart';
import 'draggable_sticker.dart';
import 'meme_text_widget.dart';

class EditorCanvas extends ConsumerStatefulWidget {
  const EditorCanvas({
    super.key,
    required this.canvasKey,
    required this.imageFile,
    required this.editorState,
  });

  final GlobalKey canvasKey;
  final File imageFile;
  final EditorState editorState;

  @override
  ConsumerState<EditorCanvas> createState() => EditorCanvasState();
}

class EditorCanvasState extends ConsumerState<EditorCanvas> {
  String? _activeOverlayId;
  final Map<String, GlobalKey> _stickerKeys = {};
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
    final isNear = EditorUtils.isNearTrash(globalPosition, _trashKey);
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
                          ColorFiltered(
                            colorFilter: EditorUtils.getFilter(widget.editorState.activeFilter),
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
                                child: MemeTextWidget(
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
                                child: MemeTextWidget(
                                  text: widget.editorState.bottomText!,
                                  font: widget.editorState.memeFont,
                                  color: widget.editorState.memeColor,
                                ),
                              ),
                            ),
                          ...widget.editorState.overlays.map((item) {
                            return DraggableSticker(
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
