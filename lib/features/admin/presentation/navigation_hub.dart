import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import '../../../core/theme/theme.dart';

class AdminNavigationHub extends StatefulWidget {
  const AdminNavigationHub({super.key});

  @override
  State<AdminNavigationHub> createState() => _AdminNavigationHubState();
}

class _AdminNavigationHubState extends State<AdminNavigationHub> {
  @override
  Widget build(BuildContext context) {
    return const AdminDashboard();
  }
}
