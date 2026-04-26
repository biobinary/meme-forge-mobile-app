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
  final double memeFontSize;

  EditorState({
    this.overlays = const [],
    this.activeFilter = 'Normal',
    this.topText,
    this.bottomText,
    this.croppedImageBytes,
    this.memeFont = 'Anton',
    this.memeColor = Colors.white,
    this.memeFontSize = 42.0,
  });

  EditorState copyWith({
    List<OverlayItem>? overlays,
    String? activeFilter,
    String? topText,
    String? bottomText,
    Uint8List? croppedImageBytes,
    String? memeFont,
    Color? memeColor,
    double? memeFontSize,
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
      memeFontSize: memeFontSize ?? this.memeFontSize,
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

  void setMemeFontSize(double size) {
    state = state.copyWith(memeFontSize: size);
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

  void applyAISuggestions({
    String? topText,
    String? bottomText,
    String? filter,
    String? font,
    Color? color,
    double? fontSize,
    List<OverlayItem>? newOverlays,
  }) {
    state = state.copyWith(
      topText: topText?.toUpperCase(),
      bottomText: bottomText?.toUpperCase(),
      activeFilter: filter,
      memeFont: font,
      memeColor: color,
      memeFontSize: fontSize,
      overlays: [...state.overlays, ...?newOverlays],
    );
  }

  void applyAIJson(Map<String, dynamic> json) {

    final List<OverlayItem> newOverlays = [];
    final stickers = json['stickers'] as List? ?? [];

    for (final s in stickers) {
      newOverlays.add(
        OverlayItem(
          id: '${DateTime.now().millisecondsSinceEpoch}${s['emoji']}',
          type: OverlayType.sticker,
          content: (s['emoji'] as String?) ?? '🔥',
          position: Offset(
            ((s['x'] as num?) ?? 0.5) * 200,
            ((s['y'] as num?) ?? 0.5) * 300,
          ),
          color: Colors.white,
          size: 64,
        ),
      );
    }

    final Color selectedColor = switch (json['textColor'] as String?) {
      'Vibrant Yellow' => const Color(0xFFFFD500),
      'Orange'         => const Color(0xFFF97316),
      'Red'            => const Color(0xFFFF5555),
      'Lime'           => const Color(0xFF00FF41),
      'Electric Indigo'=> const Color(0xFF4338CA),
      'Black'          => Colors.black,
      _                => Colors.white,
    };

    applyAISuggestions(
      topText:     json['topText']    as String?,
      bottomText:  json['bottomText'] as String?,
      filter:      json['filter']     as String?,
      font:        json['fontFamily'] as String?,
      color:       selectedColor,
      fontSize:    (json['fontSize'] as num?)?.toDouble(),
      newOverlays: newOverlays,
    );
    
  }

  void clear() {
    state = EditorState();
  }
}

final editorProvider =
    StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

final aiProcessingProvider = StateProvider<bool>((ref) => false);
