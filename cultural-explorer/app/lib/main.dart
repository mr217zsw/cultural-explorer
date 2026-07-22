import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const CulturalExplorerApp(),
    ),
  );
}

class CulturalExplorerApp extends StatelessWidget {
  const CulturalExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '华夏文化探索',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashPage(),
    );
  }
}
