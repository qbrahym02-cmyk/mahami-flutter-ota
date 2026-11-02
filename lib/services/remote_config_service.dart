import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// الإعدادات التي تتحكم بها عن بُعد من ملف `remote/config.json`.
/// أي تعديل على الملف في GitHub يصل للمستخدمين خلال دقائق — بدون تثبيت.
class RemoteConfig {
  final String appTitle;
  final Color primaryColor;
  final bool announcementEnabled;
  final String announcementText;
  final String announcementType; // info | success | warning
  final bool showStats;
  final bool showPriority;
  final bool confirmDelete;
  final List<String> quickTasks;
  final bool maintenanceEnabled;
  final String maintenanceMessage;
  final String emptyMessage;

  const RemoteConfig({
    this.appTitle = 'مهامي',
    this.primaryColor = const Color(0xFF6750A4),
    this.announcementEnabled = false,
    this.announcementText = '',
    this.announcementType = 'info',
    this.showStats = true,
    this.showPriority = true,
    this.confirmDelete = false,
    this.quickTasks = const [],
    this.maintenanceEnabled = false,
    this.maintenanceMessage = '',
    this.emptyMessage = 'لا توجد مهام بعد — أضف أول مهمة!',
  });

  static const defaults = RemoteConfig();

  factory RemoteConfig.fromJson(Map<String, dynamic> j) {
    final ann = (j['announcement'] as Map?)?.cast<String, dynamic>() ?? {};
    final feat = (j['features'] as Map?)?.cast<String, dynamic>() ?? {};
    final maint = (j['maintenance'] as Map?)?.cast<String, dynamic>() ?? {};
    const d = defaults;
    return RemoteConfig(
      appTitle: j['app_title'] as String? ?? d.appTitle,
      primaryColor: _parseColor(j['primary_color'] as String?) ?? d.primaryColor,
      announcementEnabled: ann['enabled'] as bool? ?? false,
      announcementText: ann['text'] as String? ?? '',
      announcementType: ann['type'] as String? ?? 'info',
      showStats: feat['show_stats'] as bool? ?? d.showStats,
      showPriority: feat['show_priority'] as bool? ?? d.showPriority,
      confirmDelete: feat['confirm_delete'] as bool? ?? d.confirmDelete,
      quickTasks: (j['quick_tasks'] as List?)?.whereType<String>().toList() ??
          d.quickTasks,
      maintenanceEnabled: maint['enabled'] as bool? ?? false,
      maintenanceMessage: maint['message'] as String? ?? '',
      emptyMessage: j['empty_message'] as String? ?? d.emptyMessage,
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}

class RemoteConfigService extends ChangeNotifier {
  static const _cacheKey = 'remote_config_cache';
  static const _cacheTimeKey = 'remote_config_time';

  RemoteConfig _config = RemoteConfig.defaults;
  DateTime? _lastFetched;

  RemoteConfig get config => _config;
  DateTime? get lastFetched => _lastFetched;

  /// يحمّل آخر إعدادات محفوظة (تعمل بدون إنترنت) ثم يجلب الجديدة.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _config = RemoteConfig.fromJson(jsonDecode(cached));
        final t = prefs.getString(_cacheTimeKey);
        _lastFetched = t == null ? null : DateTime.tryParse(t);
        notifyListeners();
      } catch (_) {}
    }
    await refresh();
  }

  /// يجلب config.json من GitHub. يُرجع true إذا نجح.
  Future<bool> refresh() async {
    try {
      final uri = Uri.parse(
          '${AppConfig.remoteConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final body = utf8.decode(res.bodyBytes);
      final parsed = RemoteConfig.fromJson(jsonDecode(body));
      _config = parsed;
      _lastFetched = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      await prefs.setString(_cacheTimeKey, _lastFetched!.toIso8601String());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('RemoteConfig refresh failed: $e');
      return false;
    }
  }
}
