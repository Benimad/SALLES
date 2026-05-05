import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/demande.dart';
import 'services_providers.dart';
import 'auth_provider.dart';

final demandesStreamProvider = StreamProvider.autoDispose<List<Demande>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userAsyncValue = ref.watch(authStateProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      final isAdmin = user.role == 'admin';
      return firestoreService.watchDemandes(
        userId: isAdmin ? null : user.id,
        admin: isAdmin,
      );
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final approvedDemandesStreamProvider = StreamProvider.autoDispose<List<Demande>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchApprovedDemandes();
});
