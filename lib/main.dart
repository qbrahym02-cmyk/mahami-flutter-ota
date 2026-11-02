import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'services/remote_config_service.dart';
import 'services/task_repository.dart';
import 'services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MahamiApp(
    remoteConfig: RemoteConfigService(),
    updates: UpdateService(),
    repository: TaskRepository(),
  ));
}

class MahamiApp extends StatefulWidget {
  final RemoteConfigService remoteConfig;
  final UpdateService updates;
  final TaskRepository repository;

  const MahamiApp({
    super.key,
    required this.remoteConfig,
    required this.updates,
    required this.repository,
  });

  @override
  State<MahamiApp> createState() => _MahamiAppState();
}

class _MahamiAppState extends State<MahamiApp> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.remoteConfig.init();
    widget.updates.init();
    // فحص دوري أثناء فتح التطبيق
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) => _refreshAll());
  }

  /// كلما رجع المستخدم للتطبيق نجلب آخر الإعدادات ونفحص التحديثات.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  void _refreshAll() {
    widget.remoteConfig.refresh();
    widget.updates.check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.remoteConfig,
      builder: (context, _) {
        final cfg = widget.remoteConfig.config;
        return MaterialApp(
          title: cfg.appTitle,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: cfg.primaryColor,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: cfg.primaryColor,
            brightness: Brightness.dark,
          ),
          home: HomeScreen(
            remoteConfig: widget.remoteConfig,
            updates: widget.updates,
            repository: widget.repository,
          ),
        );
      },
    );
  }
}
