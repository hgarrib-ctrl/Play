import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final savedFile = await File(file.path).copy(p.join(imagesDir.path, fileName));
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking/saving image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
    return false;
  }
}
