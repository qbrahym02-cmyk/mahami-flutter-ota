import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mahami_todo/main.dart';
import 'package:mahami_todo/services/remote_config_service.dart';
import 'package:mahami_todo/services/task_repository.dart';
import 'package:mahami_todo/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('add, complete and see a task', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'مهامي',
      packageName: 'com.mahami.mahami_todo',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(MahamiApp(
      remoteConfig: RemoteConfigService(),
      updates: UpdateService(),
      repository: TaskRepository(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مهام بعد — أضف أول مهمة!'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'شراء الخبز');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('شراء الخبز'), findsOneWidget);
    expect(find.text('أنجزت 0 من 1'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('أنجزت 1 من 1'), findsOneWidget);
  });
}
