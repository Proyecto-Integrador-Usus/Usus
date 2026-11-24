import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/catalog/data/demo_catalog_repository.dart';
import 'features/catalog/presentation/home_page.dart';

void main() {
  runApp(const UsusApp());
}

class UsusApp extends StatelessWidget {
  const UsusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usus | Renta lo que necesitas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomePage(repository: DemoCatalogRepository()),
    );
  }
}
