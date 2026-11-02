import 'package:flutter_test/flutter_test.dart';
import 'package:mahami_todo/models/task.dart';
import 'package:mahami_todo/services/remote_config_service.dart';
import 'package:mahami_todo/services/update_service.dart';

void main() {
  test('Task JSON round-trip', () {
    final t = Task.create('  اختبار  ', priority: Priority.high);
    final back = Task.fromJson(t.toJson());
    expect(back.title, 'اختبار');
    expect(back.priority, Priority.high);
    expect(back.done, false);
    expect(back.copyWith(done: true).done, true);
  });

  test('RemoteConfig parses JSON and falls back to defaults', () {
    final c = RemoteConfig.fromJson({
      'app_title': 'X',
      'primary_color': '#FF0000',
      'announcement': {'enabled': true, 'text': 'hi'},
      'features': {'show_stats': false},
      'quick_tasks': ['a', 1, 'b'],
    });
    expect(c.appTitle, 'X');
    expect(c.primaryColor.toARGB32(), 0xFFFF0000);
    expect(c.announcementEnabled, true);
    expect(c.showStats, false);
    expect(c.showPriority, true);
    expect(c.quickTasks, ['a', 'b']);
    expect(RemoteConfig.fromJson({}).appTitle, 'مهامي');
  });

  test('VersionInfo parses manifest', () {
    final v = VersionInfo.fromJson({
      'version_name': '1.2.0',
      'build_number': 7,
      'apk_url': 'https://x/app.apk',
      'sha256': '',
    });
    expect(v.buildNumber, 7);
    expect(v.sha256, isNull);
    expect(v.mandatory, false);
  });
}
