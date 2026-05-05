import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'dtulzoiyx';
  static const String apiKey = '716346312351419';
  static const String apiSecret = 'YomE3Oz0nrbYJVJodW0ReSYaI48';
  static const String uploadPreset = 'salles_preset';

  /// Upload image using unsigned preset (recommended for mobile)
  static Future<String?> uploadImage(File imageFile, {String folder = 'salles'}) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'] as String;
      }
      
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload image from URL
  static Future<String?> uploadFromUrl(String imageUrl, {String folder = 'salles'}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(timestamp, folder);

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final response = await http.post(
        uri,
        body: {
          'file': imageUrl,
          'timestamp': timestamp,
          'folder': folder,
          'api_key': apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['secure_url'] as String;
      }
      
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateDeleteSignature(publicId, timestamp);

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      
      final response = await http.post(
        uri,
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': apiKey,
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Cloudinary delete error: $e');
      return false;
    }
  }

  /// Generate upload signature
  static String _generateSignature(String timestamp, String folder) {
    final params = 'folder=$folder&timestamp=$timestamp$apiSecret';
    return sha1.convert(utf8.encode(params)).toString();
  }

  /// Generate delete signature
  static String _generateDeleteSignature(String publicId, String timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    return sha1.convert(utf8.encode(params)).toString();
  }

  /// Get optimized image URL
  static String getOptimizedUrl(String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) return imageUrl;

    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');

    final transformation = transformations.join(',');
    return imageUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }

  /// Get thumbnail URL
  static String getThumbnail(String imageUrl, {int size = 200}) {
    return getOptimizedUrl(
      imageUrl,
      width: size,
      height: size,
      quality: 'auto:low',
    );
  }
}
