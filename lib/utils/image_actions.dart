import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageActions {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 80);
    } catch (_) {
      return null;
    }
  }

  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
    } catch (_) {
      return null;
    }
  }

  static Future<File?> saveToAppDir(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final target = File(
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final bytes = await file.readAsBytes();
      await target.writeAsBytes(bytes);
      return target;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> mockUpload(File file) async {
    // Simulate network delay and a mocked prediction response.
    await Future.delayed(const Duration(seconds: 1));
    // In a real implementation, you'd POST the file to a model server here.
    // Example (commented):
    // final uri = Uri.parse('https://example.com/api/upload');
    // final req = http.MultipartRequest('POST', uri);
    // req.files.add(await http.MultipartFile.fromPath('file', file.path));
    // final res = await req.send();

    return {
      'status': 'ok',
      'prediction': 'Alimento con buena proporción de proteínas',
      'confidence': 0.82,
    };
  }
}
