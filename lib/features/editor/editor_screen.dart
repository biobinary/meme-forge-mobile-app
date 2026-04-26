import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/image_provider.dart';
import '../../core/providers/editor_provider.dart';
import 'processing_screen.dart';
import 'widgets/editor_canvas.dart';
import 'widgets/editor_toolbar.dart';

import 'widgets/ai_loading_overlay.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with WidgetsBindingObserver {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<EditorCanvasState> _editorCanvasKey = GlobalKey<EditorCanvasState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editorProvider.notifier).clear();
      _checkForBackgroundResult();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForBackgroundResult();
    }
  }

  Future<void> _checkForBackgroundResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final resultStr = prefs.getString('last_ai_suggestion');

    if (resultStr != null) {
      final json = jsonDecode(resultStr) as Map<String, dynamic>;

      // Clear result immediately to prevent double-apply
      await prefs.remove('last_ai_suggestion');

      if (!mounted) return;

      // Stop loading if active
      if (ref.read(aiProcessingProvider)) {
        ref.read(aiProcessingProvider.notifier).state = false;
      }

      // Single source of truth: delegate all parsing to EditorNotifier
      ref.read(editorProvider.notifier).applyAIJson(json);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil AI telah diterapkan! ✨'),
            backgroundColor: Color(0xFFFFD500),
          ),
        );
      }
    }
  }

  // _applyResult() removed — all AI JSON parsing is now handled
  // centrally by EditorNotifier.applyAIJson() to avoid duplication.

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
      body: Stack(
        children: [
          Column(
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
          AILoadingOverlay(
            onCancel: () {
              ref.read(aiProcessingProvider.notifier).state = false;
            },
          ),
        ],
      ),
    );
  }
}
