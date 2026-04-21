import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


enum OverlayType { text, sticker }
enum MemeTextSlot { top, bottom }

class OverlayItem {
  final String id;
  final OverlayType type;
  final String content;
  final Offset position;
  final Color color;
  final double size;
  final double scale;
  final double rotation;

  OverlayItem({
    required this.id,
    required this.type,
    required this.content,
    required this.position,
    required this.color,
    required this.size,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  OverlayItem copyWith({
    String? id,
    OverlayType? type,
    String? content,
    Offset? position,
    Color? color,
    double? size,
    double? scale,
    double? rotation,
  }) {
    return OverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      position: position ?? this.position,
      color: color ?? this.color,
      size: size ?? this.size,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class EditorState {
  final List<OverlayItem> overlays;
  final String activeFilter;

  final String? topText;
  final String? bottomText;
  final Uint8List? croppedImageBytes;
  final String memeFont;
  final Color memeColor;

  EditorState({
    this.overlays = const [],
    this.activeFilter = 'Normal',
    this.topText,
    this.bottomText,
    this.croppedImageBytes,
    this.memeFont = 'Anton',
    this.memeColor = Colors.white,
  });

  EditorState copyWith({
    List<OverlayItem>? overlays,
    String? activeFilter,
    String? topText,
    String? bottomText,
    Uint8List? croppedImageBytes,
    String? memeFont,
    Color? memeColor,
    bool clearTopText = false,
    bool clearBottomText = false,
    bool clearCrop = false,
  }) {
    return EditorState(
      overlays: overlays ?? this.overlays,
      activeFilter: activeFilter ?? this.activeFilter,
      topText: clearTopText ? null : (topText ?? this.topText),
      bottomText: clearBottomText ? null : (bottomText ?? this.bottomText),
      croppedImageBytes:
          clearCrop ? null : (croppedImageBytes ?? this.croppedImageBytes),
      memeFont: memeFont ?? this.memeFont,
      memeColor: memeColor ?? this.memeColor,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState());

  void addOverlay(OverlayItem item) {
    state = state.copyWith(overlays: [...state.overlays, item]);
  }

  void updateOverlayPosition(String id, Offset newPosition) {
    state = state.copyWith(
      overlays: state.overlays
          .map((e) => e.id == id ? e.copyWith(position: newPosition) : e)
          .toList(),
    );
  }

  void updateOverlayTransform(String id, Offset newPosition, double newScale, double newRotation) {
    state = state.copyWith(
      overlays: state.overlays
          .map((e) => e.id == id
              ? e.copyWith(position: newPosition, scale: newScale, rotation: newRotation)
              : e)
          .toList(),
    );
  }

  void removeOverlay(String id) {
    state = state.copyWith(
      overlays: state.overlays.where((e) => e.id != id).toList(),
    );
  }

  void setMemeText(MemeTextSlot slot, String text) {
    final trimmed = text.trim();
    if (slot == MemeTextSlot.top) {
      if (trimmed.isEmpty) {
        state = state.copyWith(clearTopText: true);
      } else {
        state = state.copyWith(topText: trimmed.toUpperCase());
      }
    } else {
      if (trimmed.isEmpty) {
        state = state.copyWith(clearBottomText: true);
      } else {
        state = state.copyWith(bottomText: trimmed.toUpperCase());
      }
    }
  }

  void clearMemeText(MemeTextSlot slot) {
    if (slot == MemeTextSlot.top) {
      state = state.copyWith(clearTopText: true);
    } else {
      state = state.copyWith(clearBottomText: true);
    }
  }

  void setMemeFont(String font) {
    state = state.copyWith(memeFont: font);
  }

  void setMemeColor(Color color) {
    state = state.copyWith(memeColor: color);
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void applyCroppedImage(Uint8List bytes) {
    state = state.copyWith(croppedImageBytes: bytes);
  }

  void clearCrop() {
    state = state.copyWith(clearCrop: true);
  }

  void clear() {
    state = EditorState();
  }
}

final editorProvider =
    StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});
