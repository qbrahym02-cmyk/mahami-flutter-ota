/// إعدادات مصدر التحديثات عن بُعد.
///
/// كل شيء يُقرأ من مستودع GitHub العام. لتغيير مصدر التحديث
/// (مثلاً سيرفرك الخاص) غيّر [remoteBaseUrl] فقط.
class AppConfig {
  AppConfig._();

  static const String githubOwner = 'qbrahym02-cmyk';
  static const String githubRepo = 'mahami-flutter-ota';
  static const String githubBranch = 'main';

  /// مجلد `remote/` في المستودع — يحتوي config.json و version.json
  static const String remoteBaseUrl =
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/$githubBranch/remote';

  /// إعدادات فورية (إعلانات، ألوان، ميزات...) — تصل بدون أي تثبيت.
  static const String remoteConfigUrl = '$remoteBaseUrl/config.json';

  /// معلومات آخر نسخة APK — يحدّثه GitHub Actions تلقائياً بعد كل بناء.
  static const String versionManifestUrl = '$remoteBaseUrl/version.json';

  /// كل كم دقيقة يعيد التطبيق فحص التحديثات وهو مفتوح.
  static const Duration refreshInterval = Duration(minutes: 10);
}
