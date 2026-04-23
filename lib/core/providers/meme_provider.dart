import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    // Sort client-side to avoid needing a composite index in Firestore
    memes.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    return memes;
  });
});
