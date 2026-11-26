import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/catalog/data/demo_catalog_repository.dart';
import 'features/catalog/presentation/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(UsusApp(auth: DemoAuthRepository(), preferences: preferences));
}

class UsusApp extends StatefulWidget {
  const UsusApp({super.key, required this.auth, this.preferences});
  final AuthRepository auth;
  final SharedPreferences? preferences;

  @override
  State<UsusApp> createState() => _UsusAppState();
}

class _UsusAppState extends State<UsusApp> {
  late final _settings = AppSettings(widget.preferences);
  final _catalog = DemoCatalogRepository();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _settings,
    child: HomePage(
      repository: _catalog,
      auth: widget.auth,
      settings: _settings,
    ),
    builder: (context, home) => MaterialApp(
      title: 'Usus | Renta lo que necesitas',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  );
}
