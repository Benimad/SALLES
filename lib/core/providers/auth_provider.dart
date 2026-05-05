import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import 'services_providers.dart';

final authStateProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});
