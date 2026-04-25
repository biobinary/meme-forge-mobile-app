import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/image_provider.dart';
import '../../core/providers/editor_provider.dart';
import 'processing_screen.dart';
import 'widgets/editor_canvas.dart';
import 'widgets/editor_toolbar.dart';

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
  final GlobalKey<EditorCanvasState> _editorCanvasKey = GlobalKey<EditorCanvasState>();

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
            child: EditorCanvas(
              key: _editorCanvasKey,
              canvasKey: _canvasKey,
              imageFile: currentImage,
              editorState: editorState,
            ),
          ),
          EditorToolbar(
            imageFile: currentImage,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}
