import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  /// Request camera, activity recognition and notification permissions.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    final results = <Permission, PermissionStatus>{};

    // Camera
    results[Permission.camera] = await Permission.camera.request();

    // Activity recognition (Android Q+)
    results[Permission.activityRecognition] =
        await Permission.activityRecognition.request();

    // Notifications (iOS and Android 13+)
    results[Permission.notification] = await Permission.notification.request();

    return results;
  }

  static Future<void> openSettingsIfNeeded(
      BuildContext context, Map<Permission, PermissionStatus> results) async {
    final deniedPermanent = results.entries
        .where((e) => e.value.isPermanentlyDenied)
        .map((e) => e.key)
        .toList();
    if (deniedPermanent.isNotEmpty) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permisos bloqueados'),
          content: const Text(
              'Algunos permisos están bloqueados permanentemente. ¿Deseas abrir los ajustes de la app para activarlos?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Abrir ajustes')),
          ],
        ),
      );
      if (open == true) {
        openAppSettings();
      }
    }
  }
}
