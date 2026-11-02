import 'package:flutter/material.dart';

import '../services/remote_config_service.dart';
import '../services/update_service.dart';

class AboutScreen extends StatelessWidget {
  final RemoteConfigService remoteConfig;
  final UpdateService updates;

  const AboutScreen(
      {super.key, required this.remoteConfig, required this.updates});

  String _fmt(DateTime? t) {
    if (t == null) return 'لم يتم بعد';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}/${two(t.month)}/${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق والتحديثات')),
      body: ListenableBuilder(
        listenable: Listenable.merge([remoteConfig, updates]),
        builder: (context, _) {
          final latest = updates.latest;
          final checking = updates.state == UpdateState.checking;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text('النسخة المثبّتة'),
                    subtitle: Text(
                        '${updates.currentVersion} (بناء ${updates.currentBuild})'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('أحدث نسخة على السيرفر'),
                    subtitle: Text(latest == null
                        ? '—'
                        : '${latest.versionName} (بناء ${latest.buildNumber})'),
                  ),
                  ListTile(
                    leading: Icon(_statusIcon(updates.state)),
                    title: Text(_statusText(updates)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: checking
                              ? null
                              : () => updates.check(userInitiated: true),
                          icon: checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          label: const Text('فحص التحديثات'),
                        ),
                      ),
                      if (updates.state == UpdateState.available) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              updates.downloadAndInstall();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('حدّث الآن'),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('الإعدادات عن بُعد'),
                    subtitle: Text('آخر مزامنة: ${_fmt(remoteConfig.lastFetched)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: () async {
                        final ok = await remoteConfig.refresh();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'تم جلب آخر الإعدادات ✓'
                                  : 'تعذّر الاتصال بالسيرفر')));
                        }
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'مهامك محفوظة على جهازك ولا تُمسح عند التحديث.\n'
                  'الإعلانات والألوان والميزات تُحدَّث فورياً من السيرفر، '
                  'والنسخ الجديدة تُنزَّل وتُثبَّت من داخل التطبيق مباشرة.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _statusIcon(UpdateState s) => switch (s) {
        UpdateState.available => Icons.new_releases_outlined,
        UpdateState.upToDate => Icons.verified_outlined,
        UpdateState.error => Icons.error_outline,
        UpdateState.downloading || UpdateState.installing => Icons.downloading,
        _ => Icons.hourglass_empty,
      };

  String _statusText(UpdateService u) => switch (u.state) {
        UpdateState.available => 'يوجد تحديث جديد!',
        UpdateState.upToDate => u.supportsApkUpdate
            ? 'أنت على آخر نسخة'
            : 'نسخة الويب تتحدث تلقائياً',
        UpdateState.error => u.error ?? 'خطأ',
        UpdateState.checking => 'جارِ الفحص...',
        UpdateState.downloading =>
          'جارِ التنزيل ${(u.progress * 100).round()}%',
        UpdateState.installing => 'جارِ التثبيت...',
        UpdateState.idle => '—',
      };
}
