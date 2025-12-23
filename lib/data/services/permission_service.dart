import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

class PermissionService {
  final Logger _logger = Logger();

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        _logger.i('✅ Location permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('⚠️ Location permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.w('⚠️ Location permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      _logger.e('Error checking location permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        _logger.i('✅ Notification permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('⚠️ Notification permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.w('⚠️ Notification permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (status.isGranted) {
        _logger.i('✅ Camera permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('⚠️ Camera permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.w('⚠️ Camera permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('❌ Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        _logger.i('✅ Storage permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('⚠️ Storage permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.w('⚠️ Storage permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('❌ Error requesting storage permission: $e');
      return false;
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      _logger.i('📱 Opening app settings');
    } catch (e) {
      _logger.e('❌ Error opening app settings: $e');
    }
  }

  /// Show permission dialog
  Future<bool> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Permission permission,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cấp quyền'),
          ),
        ],
      ),
    );

    if (result == true) {
      final status = await permission.request();

      if (status.isPermanentlyDenied) {
        // Show settings dialog
        if (context.mounted) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cần cấp quyền'),
              content: const Text(
                'Quyền đã bị từ chối. Vui lòng mở cài đặt ứng dụng để cấp quyền.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Mở cài đặt'),
                ),
              ],
            ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      return status.isGranted;
    }

    return false;
  }

  /// Request multiple permissions
  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final statuses = await permissions.request();
      _logger.i('📱 Multiple permissions requested');
      return statuses;
    } catch (e) {
      _logger.e('❌ Error requesting multiple permissions: $e');
      return {};
    }
  }
}
