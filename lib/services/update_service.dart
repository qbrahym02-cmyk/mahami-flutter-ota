import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

/// معلومات أحدث نسخة من `remote/version.json`
/// (يكتبه GitHub Actions تلقائياً بعد كل بناء ناجح).
class VersionInfo {
  final String versionName;
  final int buildNumber;
  final String apkUrl;
  final String? sha256;
  final String changelog;
  final bool mandatory;

  const VersionInfo({
    required this.versionName,
    required this.buildNumber,
    required this.apkUrl,
    this.sha256,
    this.changelog = '',
    this.mandatory = false,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> j) => VersionInfo(
        versionName: j['version_name'] as String? ?? '0.0.0',
        buildNumber: (j['build_number'] as num?)?.toInt() ?? 0,
        apkUrl: j['apk_url'] as String? ?? '',
        sha256: (j['sha256'] as String?)?.isEmpty == true
            ? null
            : j['sha256'] as String?,
        changelog: j['changelog'] as String? ?? '',
        mandatory: j['mandatory'] as bool? ?? false,
      );
}

enum UpdateState { idle, checking, available, upToDate, downloading, installing, error }

class UpdateService extends ChangeNotifier {
  UpdateState _state = UpdateState.idle;
  VersionInfo? _latest;
  String _currentVersion = '';
  int _currentBuild = 0;
  double _progress = 0;
  String? _error;
  bool _dismissed = false;

  UpdateState get state => _state;
  VersionInfo? get latest => _latest;
  String get currentVersion => _currentVersion;
  int get currentBuild => _currentBuild;
  double get progress => _progress;
  String? get error => _error;

  /// تحديث الـ APK داخل التطبيق مدعوم على أندرويد فقط.
  /// (نسخة الويب تتحدث تلقائياً عند إعادة النشر.)
  bool get supportsApkUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get shouldShowBanner =>
      _state == UpdateState.available && (!_dismissed || _latest!.mandatory) ||
      _state == UpdateState.downloading ||
      _state == UpdateState.installing ||
      (_state == UpdateState.error && _latest != null && !_dismissed);

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersion = info.version;
    _currentBuild = int.tryParse(info.buildNumber) ?? 0;
    notifyListeners();
    await check();
  }

  void dismiss() {
    _dismissed = true;
    notifyListeners();
  }

  /// يفحص version.json ويقارن رقم البناء بالنسخة المثبّتة.
  Future<void> check({bool userInitiated = false}) async {
    if (!supportsApkUpdate && !userInitiated) return;
    if (_state == UpdateState.downloading || _state == UpdateState.installing) {
      return;
    }
    _state = UpdateState.checking;
    _error = null;
    if (userInitiated) _dismissed = false;
    notifyListeners();
    try {
      final uri = Uri.parse(
          '${AppConfig.versionManifestUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      _latest = VersionInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final hasNewer = _latest!.buildNumber > _currentBuild &&
          _latest!.apkUrl.isNotEmpty;
      _state = hasNewer && supportsApkUpdate
          ? UpdateState.available
          : UpdateState.upToDate;
    } catch (e) {
      _state = UpdateState.error;
      _error = 'تعذّر فحص التحديثات: $e';
    }
    notifyListeners();
  }

  /// ينزّل الـ APK الجديد داخل التطبيق ثم يفتح شاشة التثبيت مباشرة.
  void downloadAndInstall() {
    final v = _latest;
    if (v == null || !supportsApkUpdate) return;
    _state = UpdateState.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();

    try {
      OtaUpdate()
          .execute(
        v.apkUrl,
        destinationFilename: 'mahami-${v.buildNumber}.apk',
        sha256checksum: v.sha256,
      )
          .listen(
        (event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              _progress = (double.tryParse(event.value ?? '') ?? 0) / 100;
              _state = UpdateState.downloading;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              _state = UpdateState.installing;
            case OtaStatus.CANCELED:
              _state = UpdateState.available;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _state = UpdateState.error;
              _error =
                  'يرجى السماح للتطبيق بتثبيت التطبيقات من الإعدادات ثم المحاولة مجدداً.';
            default:
              _state = UpdateState.error;
              _error = 'فشل التحديث (${event.status.name}): ${event.value ?? ''}';
          }
          notifyListeners();
        },
        onError: (Object e) {
          _state = UpdateState.error;
          _error = 'فشل التحديث: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      _state = UpdateState.error;
      _error = 'فشل التحديث: $e';
      notifyListeners();
    }
  }
}
