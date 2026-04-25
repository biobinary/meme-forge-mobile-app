import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  
  if (user != null) {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
        
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
  }
  return null;
});
final aiUsageProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  
  if (user != null) {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('ai_usage')
        .doc(user.uid)
        .get();
        
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
  }
  return null;
});
