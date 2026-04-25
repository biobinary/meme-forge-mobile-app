import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/editor_provider.dart';

class DraggableSticker extends ConsumerStatefulWidget {
  const DraggableSticker({
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
  ConsumerState<DraggableSticker> createState() => _DraggableStickerState();
}

class _DraggableStickerState extends ConsumerState<DraggableSticker> {
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
  void didUpdateWidget(DraggableSticker oldWidget) {
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
