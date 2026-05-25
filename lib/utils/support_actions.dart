import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class SupportActions {
  static Future<void> callNumber(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }

  static Future<void> sendEmail(String to, String subject, String body) async {
    final encoded = Uri.encodeComponent('$subject\n\n$body');
    final uri = Uri.parse(
        'mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    await launchUrl(uri);
  }

  static Future<XFile?> openCamera() async {
    final picker = ImagePicker();
    try {
      final file =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      return file;
    } catch (e) {
      return null;
    }
  }
}
