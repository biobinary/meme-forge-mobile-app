import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meme_model.dart';
import 'auth_provider.dart';

final userMemesProvider = StreamProvider<List<MemeModel>>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('memes')
      .where('user_id', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    final memes = snapshot.docs
        .map((doc) => MemeModel.fromMap(doc.data(), doc.id))
        .toList();
    
    memes.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    return memes;
  });
});

final randomFeedProvider = FutureProvider.autoDispose<List<MemeModel>>((ref) async {
  final repository = ref.watch(memeRepositoryProvider);
  return repository.getRandomMemes(limit: 10);
});

final memeRepositoryProvider = Provider((ref) => MemeRepository());

class MemeRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<MemeModel>> getRandomMemes({int limit = 10}) async {
    // Fetch a larger chunk and shuffle in-memory for randomness
    // In a real production app with millions of docs, we'd use a different strategy
    final snapshot = await _db
        .collection('memes')
        .limit(50)
        .get();

    final memes = snapshot.docs
        .map((doc) => MemeModel.fromMap(doc.data(), doc.id))
        .toList();

    memes.shuffle();
    return memes.take(limit).toList();
  }

  Future<void> updateMemeCaption(String memeId, String newCaption) async {
    await _db.collection('memes').doc(memeId).update({
      'caption': newCaption,
    });
  }

  Future<void> deleteMeme(String memeId, String imageUrl) async {
    
    await _db.collection('memes').doc(memeId).delete();

    try {
      
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.contains('memes-bucket')) {
        final fileName = pathSegments.last;
        await Supabase.instance.client.storage
            .from('memes-bucket')
            .remove([fileName]);
        debugPrint('Berhasil menghapus gambar dari storage: $fileName');
      }

    } catch (e) {
      debugPrint('Gagal menghapus gambar dari storage: $e');

    }
  }
}
