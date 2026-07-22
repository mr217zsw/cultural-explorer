import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeIn)),
    );
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    try {
      await context.read<AuthProvider>().init();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnim, _fadeAnim]),
            builder: (context, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(scale: _scaleAnim.value, child: child),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.temple_buddhist, size: 88, color: Colors.white),
                SizedBox(height: AppTheme.spacingXxl),
                Text(
                  '华夏文化探索',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text(
                  '读山河 · 知历史 · 见人文',
                  style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
