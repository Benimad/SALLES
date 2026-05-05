import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/salle.dart';
import 'services_providers.dart';

final sallesStreamProvider = StreamProvider.autoDispose<List<Salle>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchSalles();
});
