import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../widgets/common/update_dialog.dart';

class VersionCheckService {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  final _supabase = Supabase.instance.client;

  Future<void> checkVersion(BuildContext context) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 2. Determine platform
      final platform = Platform.isAndroid ? 'android' : 'ios';
      
      // 3. Query Supabase
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .single();
      
      final minVersion = response['min_version'] as String;
      final latestVersion = response['latest_version'] as String;
      final maintenanceMode = response['maintenance_mode'] as bool? ?? false;
      final updateUrl = response['update_url'] as String?; // Store URL

      // 4. Check for Maintenance Mode
      if (maintenanceMode && context.mounted) {
        _showMaintenanceDialog(context, response['maintenance_message'] ?? 'We are undergoing maintenance.');
        return;
      }

      // 5. Compare Versions
      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        if (context.mounted) {
          // If current < min_version, it's a FORCE update (not dismissible)
          final isForceUpdate = _isUpdateAvailable(currentVersion, minVersion);
          
          UpdateDialog.show(context); // We can enhance this to handle force updates
        }
      }

    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  bool _isUpdateAvailable(String current, String target) {
    // Simple semantic version comparison
    // Returns true if current < target
    List<int> cParts = current.split('.').map(int.parse).toList();
    List<int> tParts = target.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < cParts.length ? cParts[i] : 0;
      int t = i < tParts.length ? tParts[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }

  void _showMaintenanceDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Maintenance'),
        content: Text(message),
      ),
    );
  }
}
