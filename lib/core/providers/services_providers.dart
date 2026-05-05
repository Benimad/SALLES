import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/firebase_auth_service.dart';
import '../../shared/services/firestore_service.dart';

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
