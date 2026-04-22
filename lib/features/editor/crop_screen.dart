import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  
  static const _ratios = <String, double?>{
    'Free': null,
    '1:1': 1.0,
    '4:5': 4 / 5,
    '16:9': 16 / 9,
  };

  String _selectedRatio = 'Free';

  ui.Image? _uiImage;
  Size _previewSize = Size.zero;  
  final ValueNotifier<Rect> _cropRectNotifier = ValueNotifier<Rect>(Rect.zero);
  Rect get _cropRect => _cropRectNotifier.value;
  set _cropRect(Rect value) => _cropRectNotifier.value = value;
  Rect _imageRect = Rect.zero;

  bool _isApplying = false;
  bool _imageLoaded = false;

  @override
  void dispose() {
    _cropRectNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _uiImage = frame.image;
        _imageLoaded = true;
      });
    }
  }


  void _recalculateRects(Size previewSize) {

    if (!_imageLoaded || _uiImage == null) return;
    if (previewSize == _previewSize && _imageRect != Rect.zero) return;

    _previewSize = previewSize;

    final imgW = _uiImage!.width.toDouble();
    final imgH = _uiImage!.height.toDouble();

    final scaleX = previewSize.width / imgW;
    final scaleY = previewSize.height / imgH;
    final scale = math.min(scaleX, scaleY);

    final fitW = imgW * scale;
    final fitH = imgH * scale;
    final offsetX = (previewSize.width - fitW) / 2;
    final offsetY = (previewSize.height - fitH) / 2;

    _imageRect = Rect.fromLTWH(offsetX, offsetY, fitW, fitH);

    // Inisialisasi cropRect hanya sekali
    if (_cropRect == Rect.zero || _imageRect != Rect.zero) {
      _cropRect = _applyRatio(_imageRect, _ratios[_selectedRatio]);
    }
  }

  // Menerapkan rasio ke dalam imageRect — mengembalikan crop rect yang sesuai
  Rect _applyRatio(Rect imageRect, double? ratio) {
    if (ratio == null) return imageRect;

    final availW = imageRect.width;
    final availH = imageRect.height;
    final imageRatio = availW / availH;

    double cropW, cropH;
    if (ratio <= imageRatio) {
      cropH = availH;
      cropW = cropH * ratio;
    } else {
      cropW = availW;
      cropH = cropW / ratio;
    }

    final left = imageRect.left + (availW - cropW) / 2;
    final top = imageRect.top + (availH - cropH) / 2;
    return Rect.fromLTWH(left, top, cropW, cropH);
  }

  void _onRatioChanged(String ratioName) {
    setState(() {
      _selectedRatio = ratioName;
      _cropRect = _applyRatio(_imageRect, _ratios[ratioName]);
    });
  }

  Rect _clamp(Rect rect) {
    const minSize = 40.0;
    double l = rect.left.clamp(_imageRect.left, _imageRect.right - minSize);
    double t = rect.top.clamp(_imageRect.top, _imageRect.bottom - minSize);
    double r = rect.right.clamp(_imageRect.left + minSize, _imageRect.right);
    double b = rect.bottom.clamp(_imageRect.top + minSize, _imageRect.bottom);
    return Rect.fromLTRB(l, t, r, b);
  }

  static const double _handleZone = 56.0;

  _DragHandle? _activeHandle;

  _DragHandle? _hitTest(Offset pos) {
    final r = _cropRect;

    // Corners (priority)
    if ((pos - r.topLeft).distance < _handleZone) return _DragHandle.topLeft;
    if ((pos - r.topRight).distance < _handleZone) return _DragHandle.topRight;
    if ((pos - r.bottomLeft).distance < _handleZone) return _DragHandle.bottomLeft;
    if ((pos - r.bottomRight).distance < _handleZone) return _DragHandle.bottomRight;

    // Edges
    final midTop = Offset(r.center.dx, r.top);
    final midBottom = Offset(r.center.dx, r.bottom);
    final midLeft = Offset(r.left, r.center.dy);
    final midRight = Offset(r.right, r.center.dy);
    if ((pos - midTop).distance < _handleZone) return _DragHandle.top;
    if ((pos - midBottom).distance < _handleZone) return _DragHandle.bottom;
    if ((pos - midLeft).distance < _handleZone) return _DragHandle.left;
    if ((pos - midRight).distance < _handleZone) return _DragHandle.right;

    // Inside crop = move whole rect
    if (r.contains(pos)) return _DragHandle.move;

    return null;
  }

  void _onPanStart(DragStartDetails d) {
    _activeHandle = _hitTest(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeHandle == null) return;
    final dx = d.delta.dx;
    final dy = d.delta.dy;
    final r = _cropRect;

    Rect next;
    switch (_activeHandle!) {
      case _DragHandle.move:
        next = r.shift(Offset(dx, dy));
        // clamp to imageRect
        final shifted = Rect.fromLTWH(
          next.left.clamp(_imageRect.left, _imageRect.right - r.width),
          next.top.clamp(_imageRect.top, _imageRect.bottom - r.height),
          r.width,
          r.height,
        );
        next = shifted;
        break;
      case _DragHandle.topLeft:
        next = Rect.fromLTRB(r.left + dx, r.top + dy, r.right, r.bottom);
        break;
      case _DragHandle.topRight:
        next = Rect.fromLTRB(r.left, r.top + dy, r.right + dx, r.bottom);
        break;
      case _DragHandle.bottomLeft:
        next = Rect.fromLTRB(r.left + dx, r.top, r.right, r.bottom + dy);
        break;
      case _DragHandle.bottomRight:
        next = Rect.fromLTRB(r.left, r.top, r.right + dx, r.bottom + dy);
        break;
      case _DragHandle.top:
        next = Rect.fromLTRB(r.left, r.top + dy, r.right, r.bottom);
        break;
      case _DragHandle.bottom:
        next = Rect.fromLTRB(r.left, r.top, r.right, r.bottom + dy);
        break;
      case _DragHandle.left:
        next = Rect.fromLTRB(r.left + dx, r.top, r.right, r.bottom);
        break;
      case _DragHandle.right:
        next = Rect.fromLTRB(r.left, r.top, r.right + dx, r.bottom);
        break;
    }

    // Jika ada ratio lock, paksa rasio setelah resize
    final ratio = _ratios[_selectedRatio];
    if (ratio != null && _activeHandle != _DragHandle.move) {
      next = _enforceRatio(next, ratio, _activeHandle!);
    }

    _cropRect = _clamp(next);
  }

  void _onPanEnd(DragEndDetails d) {
    _activeHandle = null;
  }

  Rect _enforceRatio(Rect r, double ratio, _DragHandle handle) {
    switch (handle) {
      case _DragHandle.topLeft:
      case _DragHandle.bottomLeft:
      case _DragHandle.left:
        final newH = r.width / ratio;
        return Rect.fromLTWH(r.left, r.top, r.width, newH);
      default:
        final newH = r.width / ratio;
        return Rect.fromLTWH(r.left, r.top, r.width, newH);
    }
  }

  Future<void> _applyCrop() async {
    if (_uiImage == null || _imageRect == Rect.zero) return;
    setState(() => _isApplying = true);

    try {

      final scaleX = _uiImage!.width / _imageRect.width;
      final scaleY = _uiImage!.height / _imageRect.height;

      final srcLeft = (_cropRect.left - _imageRect.left) * scaleX;
      final srcTop = (_cropRect.top - _imageRect.top) * scaleY;
      final srcWidth = _cropRect.width * scaleX;
      final srcHeight = _cropRect.height * scaleY;

      final srcRect = Rect.fromLTWH(
        srcLeft.clamp(0, _uiImage!.width.toDouble()),
        srcTop.clamp(0, _uiImage!.height.toDouble()),
        srcWidth.clamp(1, _uiImage!.width.toDouble() - srcLeft),
        srcHeight.clamp(1, _uiImage!.height.toDouble() - srcTop),
      );

      // Render cropped image ke PictureRecorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final destRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
      canvas.drawImageRect(_uiImage!, srcRect, destRect, Paint());

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        srcRect.width.round(),
        srcRect.height.round(),
      );

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null && mounted) {
        final bytes = byteData.buffer.asUint8List();
        Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal crop: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          'CROP',
          style: GoogleFonts.anton(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          if (_isApplying)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD500),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _imageLoaded ? _applyCrop : null,
              child: Text(
                'Terapkan',
                style: GoogleFonts.nunito(
                  textStyle: const TextStyle(
                    color: Color(0xFFFFD500),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_imageLoaded
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD500)),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      _recalculateRects(size);
                      return GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: Stack(
                            children: [
                              // Gambar asli sebagai background preview
                              Positioned.fill(
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Crop overlay: dim region + grid + handles
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _CropPainter(
                                    imageRect: _imageRect,
                                    cropRectNotifier: _cropRectNotifier,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            color: const Color(0xFF18181B),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ratio Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _ratios.keys.map((name) {
                      final selected = _selectedRatio == name;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => _onRatioChanged(name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFD500)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFFD500)
                                    : Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              name,
                              style: GoogleFonts.nunito(
                                textStyle: TextStyle(
                                  color: selected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Reset button
                  TextButton.icon(
                    onPressed: () {
                      _cropRect = _applyRatio(
                        _imageRect,
                        _ratios[_selectedRatio],
                      );
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                    label: Text(
                      'Reset',
                      style: GoogleFonts.nunito(
                        textStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DragHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  move,
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.imageRect,
    required this.cropRectNotifier,
  }) : super(repaint: cropRectNotifier);

  final Rect imageRect;
  final ValueNotifier<Rect> cropRectNotifier;

  @override
  void paint(Canvas canvas, Size size) {
    
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cropRect = cropRectNotifier.value;

    if (imageRect != Rect.zero && cropRect != Rect.zero) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, cropRect.top),
        dimPaint,
      );
      canvas.drawRect(
        Rect.fromLTRB(0, cropRect.bottom, size.width, size.height),
        dimPaint,
      );
      canvas.drawRect(
        Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom),
        dimPaint,
      );
      canvas.drawRect(
        Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom),
        dimPaint,
      );
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(cropRect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;

    // Vertical grid lines
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + thirdW * i;
      canvas.drawLine(Offset(x, cropRect.top), Offset(x, cropRect.bottom), gridPaint);
    }
    // Horizontal grid lines
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + thirdH * i;
      canvas.drawLine(Offset(cropRect.left, y), Offset(cropRect.right, y), gridPaint);
    }

    // Corner handles
    _drawCornerHandle(canvas, cropRect.topLeft, _Corner.topLeft);
    _drawCornerHandle(canvas, cropRect.topRight, _Corner.topRight);
    _drawCornerHandle(canvas, cropRect.bottomLeft, _Corner.bottomLeft);
    _drawCornerHandle(canvas, cropRect.bottomRight, _Corner.bottomRight);

    // Edge mid-handles
    _drawMidHandle(canvas, Offset(cropRect.center.dx, cropRect.top), _Edge.top);
    _drawMidHandle(canvas, Offset(cropRect.center.dx, cropRect.bottom), _Edge.bottom);
    _drawMidHandle(canvas, Offset(cropRect.left, cropRect.center.dy), _Edge.left);
    _drawMidHandle(canvas, Offset(cropRect.right, cropRect.center.dy), _Edge.right);
  }

  static const double _cornerLen = 20;
  static const double _cornerThick = 3.5;
  static const double _midSize = 6;

  void _drawCornerHandle(Canvas canvas, Offset corner, _Corner pos) {
    final p = Paint()
      ..color = const Color(0xFFFFD500)
      ..strokeWidth = _cornerThick
      ..strokeCap = StrokeCap.round;

    const h = _cornerLen;
    final sign = (pos == _Corner.topLeft || pos == _Corner.bottomLeft) ? 1.0 : -1.0;
    final sign2 = (pos == _Corner.topLeft || pos == _Corner.topRight) ? 1.0 : -1.0;

    canvas.drawLine(corner, corner + Offset(h * sign, 0), p);
    canvas.drawLine(corner, corner + Offset(0, h * sign2), p);
  }

  void _drawMidHandle(Canvas canvas, Offset center, _Edge edge) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _midSize / 2, p);
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.imageRect != imageRect;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }
enum _Edge { top, bottom, left, right }
