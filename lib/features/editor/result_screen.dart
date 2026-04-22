import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List pngBytes;

  const ResultScreen({super.key, required this.pngBytes});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isCaptionEmpty = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_onCaptionChanged);
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _captionController.dispose();
    super.dispose();
  }

  void _onCaptionChanged() {
    setState(() {
      _isCaptionEmpty = _captionController.text.trim().isEmpty;
    });
  }

  Future<void> _downloadImage() async {
    try {
      
      if (Platform.isAndroid) {
      
        bool isGranted = false;
      
        if (await Permission.storage.isGranted || await Permission.photos.isGranted) {
          isGranted = true;
      
        } else {

          final storageStatus = await Permission.storage.request();
          
          if (storageStatus.isGranted) {
            isGranted = true;
          
          } else {

            final photosStatus = await Permission.photos.request();
            if (photosStatus.isGranted || photosStatus.isLimited) {
              isGranted = true;
            }

          }

        }

        if (!isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin galeri diperlukan untuk menyimpan gambar')),
            );
          }
          return;
        }
      }

      final result = await ImageGallerySaverPlus.saveImage(
        widget.pngBytes,
        quality: 100,
        name: "meme_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meme berhasil disimpan ke galeri!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan meme.')),
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/meme_share.png').create();
      await file.writeAsBytes(widget.pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _captionController.text.isNotEmpty 
            ? _captionController.text 
            : 'Check out my meme from Meme Forge!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSaveMeme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      
      final fileName = 'meme_${DateTime.now().millisecondsSinceEpoch}.png';
      
      await Supabase.instance.client.storage
          .from('memes-bucket')
          .uploadBinary(
            fileName,
            widget.pngBytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('memes-bucket')
          .getPublicUrl(fileName);

      await FirebaseFirestore.instance.collection('memes').add({
        'user_id': user.uid,
        'image_url': publicUrl,
        'caption': _captionController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meme berhasil diupload!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupload meme: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('READY TO FORGE'),
        actions: [
          TextButton(
            onPressed: (_isCaptionEmpty || _isUploading) ? null : _uploadAndSaveMeme,
            child: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: isDark ? const Color(0xFFFFD500) : Colors.black,
                    ),
                  )
                : Text(
                    'UPLOAD',
                    style: GoogleFonts.anton(
                      fontSize: 18,
                      color: (_isCaptionEmpty || _isUploading) 
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : (isDark ? const Color(0xFFFFD500) : Colors.black),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Image Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black,
                  width: 2,
                ),
                boxShadow: isDark ? [] : const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(6, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                widget.pngBytes,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Caption Section
            Text(
              'TAMBAHKAN CAPTION',
              style: GoogleFonts.anton(
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Tulis sesuatu yang lucu...',
                hintStyle: GoogleFonts.nunito(color: isDark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.5),
                ),
              ),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // Action Buttons Section
            Text(
              'BAGIKAN HASIL KARYAMU',
              style: GoogleFonts.anton(
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'DOWNLOAD',
                    icon: Icons.download_rounded,
                    onPressed: _downloadImage,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'SHARE',
                    icon: Icons.share_rounded,
                    onPressed: _shareImage,
                    isDark: isDark,
                    color: const Color(0xFF4338CA), // Electric Indigo
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;
  final Color? color;
  final Color? textColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDark,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? (isDark ? const Color(0xFFFFD500) : const Color(0xFFFFD500)),
        foregroundColor: textColor ?? Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
