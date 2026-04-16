import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _authService.getCurrentUser();
    if (mounted) setState(() { _user = user; _isLoading = false; });
  }

  void _editProfile() {
    if (_user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: _user!,
        onSave: (nom, prenom, phone, dept) async {
          Navigator.pop(context);
          final res = await _apiService.updateProfile(_user!.id, nom, prenom, phone, dept);
          if (!mounted) return;
          if (res['success'] == true) {
            await _authService.updateUserLocally(nom, prenom, phone, dept);
            _load();
            _toast('Profil mis à jour', AppColors.secondary);
          } else {
            _toast(res['message'] ?? 'Erreur', AppColors.error);
          }
        },
      ),
    );
  }

  void _changePassword() {
    if (_user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        userId: _user!.id,
        onSave: (current, next) async {
          Navigator.pop(context);
          final res = await _apiService.changePassword(_user!.id, current, next);
          if (!mounted) return;
          if (res['success'] == true) {
            _toast('Mot de passe modifié', AppColors.secondary);
          } else {
            _toast(res['message'] ?? 'Erreur', AppColors.error);
          }
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Déconnexion',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        content: const Text(
          'Voulez-vous vous déconnecter ?',
          style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: AppColors.navyBlue,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _user != null
                                      ? '${_user!.prenom[0]}${_user!.nom[0]}'.toUpperCase()
                                      : '??',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _user != null ? '${_user!.prenom} ${_user!.nom}' : '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _user?.role == 'admin'
                                    ? AppColors.primaryContainer.withOpacity(0.4)
                                    : AppColors.secondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _user?.role == 'admin' ? 'ADMINISTRATEUR' : 'EMPLOYÉ',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: RedAccentBar()),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Info card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              _infoTile(
                                Icons.email_rounded,
                                'Email',
                                _user?.email ?? '-',
                              ),
                              if (_user?.phone != null && _user!.phone!.isNotEmpty)
                                _infoTile(
                                  Icons.phone_rounded,
                                  'Téléphone',
                                  _user!.phone!,
                                ),
                              if (_user?.department != null && _user!.department!.isNotEmpty)
                                _infoTile(
                                  Icons.business_rounded,
                                  'Département',
                                  _user!.department!,
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Actions
                        _actionTile(
                          icon: Icons.edit_rounded,
                          label: 'Modifier le profil',
                          color: AppColors.primary,
                          onTap: _editProfile,
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Changer le mot de passe',
                          color: AppColors.secondary,
                          onTap: _changePassword,
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.logout_rounded,
                          label: 'Se déconnecter',
                          color: AppColors.error,
                          onTap: _logout,
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          'Salles v1.0 — Groupe Al Omrane',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: AppColors.outlineVariant.withOpacity(0.15), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final User user;
  final Function(String nom, String prenom, String? phone, String? dept) onSave;
  const _EditProfileSheet({required this.user, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _deptCtrl;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.user.nom);
    _prenomCtrl = TextEditingController(text: widget.user.prenom);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _deptCtrl = TextEditingController(text: widget.user.department ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text('Modifier le profil',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _tf(_prenomCtrl, 'Prénom *', required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _tf(_nomCtrl, 'Nom *', required: true)),
                    ]),
                    const SizedBox(height: 12),
                    _tf(_phoneCtrl, 'Téléphone', keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _tf(_deptCtrl, 'Département'),
                    const SizedBox(height: 20),
                    PrimaryGradientButton(
                      label: 'Enregistrer',
                      icon: Icons.save_rounded,
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        widget.onSave(
                          _nomCtrl.text.trim(),
                          _prenomCtrl.text.trim(),
                          _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
                          _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String hint,
      {bool required = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final int userId;
  final Function(String current, String next) onSave;
  const _ChangePasswordSheet({required this.userId, required this.onSave});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text('Changer le mot de passe',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _pwField(_currentCtrl, 'Mot de passe actuel', _showCurrent,
                        () => setState(() => _showCurrent = !_showCurrent)),
                    const SizedBox(height: 12),
                    _pwField(_newCtrl, 'Nouveau mot de passe', _showNew,
                        () => setState(() => _showNew = !_showNew),
                        minLength: 6),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showNew,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                      decoration: _inputDecor('Confirmer le mot de passe'),
                      validator: (v) => v != _newCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                    ),
                    const SizedBox(height: 20),
                    PrimaryGradientButton(
                      label: 'Changer',
                      icon: Icons.lock_rounded,
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        widget.onSave(_currentCtrl.text, _newCtrl.text);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String hint, bool show,
      VoidCallback toggle, {int minLength = 1}) {
    return TextFormField(
      controller: ctrl,
      obscureText: !show,
      style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
      decoration: _inputDecor(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 18, color: AppColors.onSurfaceVariant),
          onPressed: toggle,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ requis';
        if (v.length < minLength) return 'Minimum $minLength caractères';
        return null;
      },
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
