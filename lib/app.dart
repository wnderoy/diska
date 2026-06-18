import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scaffold.dart';

class BamapApp extends StatelessWidget {
  const BamapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bamap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.blackAndWhite,
      home: const AppScaffold(),
    );
  }
}
