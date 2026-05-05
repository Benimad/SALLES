import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user.dart' as app_user;
import '../../core/constants/constants.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> register(
      String nom, String prenom, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': AppConstants.roleEmployee,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Compte créé avec succès'};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'Utilisateur introuvable'};
      }

      final userData = userDoc.data()!;
      final user = app_user.User(
        id: userCredential.user!.uid,
        nom: userData['nom'],
        prenom: userData['prenom'],
        email: userData['email'],
        role: userData['role'],
        phone: userData['phone'],
        department: userData['department'],
      );

      await _saveUserData(user, userCredential.user!.uid);
      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<void> _saveUserData(app_user.User user, String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, firebaseUid);
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userRoleKey, user.role);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('firebase_uid', firebaseUid);
  }

  Future<app_user.User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return app_user.User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_uid');
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<void> updateUserLocally(
      String nom, String prenom, String? phone, String? department) async {
    final user = await getCurrentUser();
    if (user == null) return;
    final updated = app_user.User(
      id: user.id,
      nom: nom,
      prenom: prenom,
      email: user.email,
      role: user.role,
      phone: phone,
      department: department,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(updated.toJson()));
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email non trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Email déjà utilisé';
      case 'weak-password':
        return 'Mot de passe trop faible';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Erreur d\'authentification';
    }
  }
}
