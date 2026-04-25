import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kMemesBucket = 'memes-bucket';
const _kMemesCollection = 'memes';

class UploadService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;

  UploadService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SupabaseClient? supabase,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _supabase = supabase ?? Supabase.instance.client;

  Future<void> uploadMeme({
    required Uint8List pngBytes,
    required String caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User belum login. Tidak dapat mengupload meme.');
    }

    final fileName = 'meme_${DateTime.now().millisecondsSinceEpoch}.png';

    await _supabase.storage.from(_kMemesBucket).uploadBinary(
          fileName,
          pngBytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    final publicUrl =
        _supabase.storage.from(_kMemesBucket).getPublicUrl(fileName);

    await _firestore.collection(_kMemesCollection).add({
      'user_id': user.uid,
      'image_url': publicUrl,
      'caption': caption.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'likes': <String>[],
    });
  }

  Future<bool> downloadToGallery(Uint8List pngBytes) async {

    if (Platform.isAndroid) {
      final granted = await _requestGalleryPermission();
      if (!granted) return false;
    }

    final result = await ImageGallerySaverPlus.saveImage(
      pngBytes,
      quality: 100,
      name: 'meme_${DateTime.now().millisecondsSinceEpoch}',
    );

    return result['isSuccess'] == true;

  }

  Future<bool> _requestGalleryPermission() async {
    if (await Permission.storage.isGranted ||
        await Permission.photos.isGranted) {
      return true;
    }

    if ((await Permission.storage.request()).isGranted) return true;

    final photosStatus = await Permission.photos.request();
    return photosStatus.isGranted || photosStatus.isLimited;
  }

  Future<void> shareImage({
    required Uint8List pngBytes,
    String shareText = 'Check out my meme from Meme Forge!',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/meme_share.png').create();
    await file.writeAsBytes(pngBytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: shareText,
      ),
    );
  }
}
