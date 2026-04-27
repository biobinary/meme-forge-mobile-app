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
  final GlobalKey _trashKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();

  void prepareForExport() {
    setState(() {
      _activeOverlayId = null;
    });
  }

  void restoreAfterExport() {
  }

  Rect? get imageRect {
    final canvasBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (canvasBox != null && imageBox != null) {
      final canvasPos = canvasBox.localToGlobal(Offset.zero);
      final imagePos = imageBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        imagePos.dx - canvasPos.dx,
        imagePos.dy - canvasPos.dy,
        imageBox.size.width,
        imageBox.size.height,
      );
    }
    return null;
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
                minScale: 1.0, 
                maxScale: 1.0,
                child: RepaintBoundary(
                  key: widget.canvasKey,
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    color: Colors.black, 
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The Image Layer - Centered
                        Center(
                          child: Stack(
                            key: _imageKey,
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
                              // Meme Text - Bound to Image boundaries
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
                                      fontSize: widget.editorState.memeFontSize,
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
                                      fontSize: widget.editorState.memeFontSize,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Sticker Layer - Allowed to move everywhere
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
                            color: Colors.black.withValues(alpha: 0.5),
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

