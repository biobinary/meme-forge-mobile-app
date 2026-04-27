import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'result_screen.dart';

typedef OnRenderComplete = void Function(Uint8List pngBytes);

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.canvasKey,
    required this.sourceFile,
    this.cropRect,
  });

  final GlobalKey canvasKey;
  final File sourceFile;
  final Rect? cropRect;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {

  late final AnimationController _pulseCtrl;
  late final AnimationController _dotCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;

  int _step = 0; 
  static const _steps = [
    'Memproses perubahan…',
    'Mengonversi ke PNG…',
    'Finalising output…',
  ];
  bool _error = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startRendering());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRendering() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _step = 0);

      final renderObject = widget.canvasKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('Canvas render boundary not found.');
      }

      ui.Image fullImage = await renderObject.toImage(pixelRatio: 3.0);

      if (widget.cropRect != null) {
    
        final rect = widget.cropRect!;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
        const double pr = 3.0;
        final srcRect = Rect.fromLTWH(
          rect.left * pr,
          rect.top * pr,
          rect.width * pr,
          rect.height * pr,
        );
  
        final dstRect = Rect.fromLTWH(0, 0, rect.width * pr, rect.height * pr);

        canvas.drawImageRect(
          fullImage,
          srcRect,
          dstRect,
          Paint()..filterQuality = ui.FilterQuality.high,
        );

        final picture = recorder.endRecording();
        final croppedImage = await picture.toImage(
          (rect.width * pr).round(),
          (rect.height * pr).round(),
        );
        
        fullImage.dispose();
        fullImage = croppedImage;
      }

      if (!mounted) return;
      setState(() => _step = 1);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final ByteData? byteData =
          await fullImage.toByteData(format: ui.ImageByteFormat.png);
      fullImage.dispose();

      if (byteData == null) throw Exception('Failed to encode image.');

      final pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      setState(() => _step = 2);
      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        _buildRoute(ResultScreen(pngBytes: pngBytes)),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _error = true);
      debugPrint('[ProcessingScreen] render error: $e');
    
    }

  }

  PageRouteBuilder<void> _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: _error ? _buildError() : _buildLoading(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD500),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(6, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: Colors.black,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'MEMPROSES',
              style: GoogleFonts.anton(
                textStyle: const TextStyle(
                  color: Color(0xFFFFD500),
                  fontSize: 32,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Meme kamu sedang disiapkan…',
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 40),

            _StepIndicator(currentStep: _step),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _steps[_step],
                key: ValueKey(_step),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            _AnimatedDots(controller: _dotCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5555),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(5, 5)),
                ],
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 32),
            Text(
              'GAGAL MEMPROSES',
              style: GoogleFonts.anton(
                textStyle: const TextStyle(
                  color: Color(0xFFFF5555),
                  fontSize: 28,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Terjadi kesalahan saat merender gambar.\nKembali ke editor dan coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD500),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'Kembali ke Editor',
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const totalSteps = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 40 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF4338CA)
                : isActive
                    ? const Color(0xFFFFD500)
                    : Colors.white12,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? Colors.black : Colors.transparent,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value; // 0.0 → 1.0 looping
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase
            final phase = (t - i * 0.25).abs() % 1.0;
            final size = 8.0 + 6.0 * (1.0 - (phase * 2 - 1.0).abs().clamp(0.0, 1.0));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD500),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
