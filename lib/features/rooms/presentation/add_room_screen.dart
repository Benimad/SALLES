import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../shared/services/cloudinary_service.dart';

class AddRoomWithImageScreen extends StatefulWidget {
  const AddRoomWithImageScreen({super.key});

  @override
  State<AddRoomWithImageScreen> createState() => _AddRoomWithImageScreenState();
}

class _AddRoomWithImageScreenState extends State<AddRoomWithImageScreen> {
  final _nomCtrl = TextEditingController();
  final _capaciteCtrl = TextEditingController();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImageUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    final imageUrl = await CloudinaryService.uploadImage(
      _selectedImage!,
      folder: 'salles/rooms',
    );

    setState(() {
      _isUploading = false;
      if (imageUrl != null) {
        _uploadedImageUrl = imageUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploadée avec succès!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'upload')),
        );
      }
    });
  }

  Future<void> _saveRoom() async {
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez uploader une image')),
      );
      return;
    }

    // Save room with image URL to Firestore or PHP backend
    final roomData = {
      'nom': _nomCtrl.text,
      'capacite': int.parse(_capaciteCtrl.text),
      'image_url': _uploadedImageUrl,
      'image_thumbnail': CloudinaryService.getThumbnail(_uploadedImageUrl!),
    };

    print('Room data: $roomData');
    
    // TODO: Save to backend
    // await FirestoreService().addSalle(roomData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une salle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la salle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capaciteCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacité',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Image picker
            if (_selectedImage != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isUploading && _uploadedImageUrl == null)
                    ElevatedButton.icon(
                      onPressed: _uploadImage,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload vers Cloudinary'),
                    ),
                  if (_isUploading)
                    const CircularProgressIndicator(),
                  if (_uploadedImageUrl != null)
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 8),
                        const Text('Image uploadée!'),
                        const SizedBox(height: 8),
                        Text(
                          _uploadedImageUrl!,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Choisir une image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(48),
                ),
              ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _uploadedImageUrl != null ? _saveRoom : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Enregistrer la salle'),
            ),
          ],
        ),
      ),
    );
  }
}
