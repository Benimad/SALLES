import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Sélectionner un fichier (PDF, DOC, etc.)
  Future<File?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la sélection du fichier: $e');
      return null;
    }
  }

  // Sélectionner plusieurs fichiers
  Future<List<File>> pickMultipleFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la sélection des fichiers: $e');
      return [];
    }
  }

  // Upload un fichier vers Firebase Storage
  Future<Map<String, dynamic>> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return {
        'success': true,
        'url': downloadUrl,
        'name': file.path.split('/').last,
      };
    } catch (e) {
      debugPrint('Erreur lors de l\'upload: $e');
      return {'success': false, 'message': 'Erreur lors de l\'upload: $e'};
    }
  }

  // Obtenir la taille du fichier en format lisible
  String getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Obtenir l'extension du fichier
  String getFileExtension(File file) {
    return file.path.split('.').last.toUpperCase();
  }

  // Vérifier si le fichier est une image
  bool isImage(File file) {
    final ext = getFileExtension(file).toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
  }

  // Supprimer un fichier local
  Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }
}
