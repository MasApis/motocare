import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shared/demo/component_preview_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Inisialisasi Firebase jika konfigurasi platform sudah tersedia.
    // Jika belum terkonfigurasi, aplikasi tetap dapat berjalan untuk pengujian scaffolding.
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase belum dikonfigurasi via flutterfire configure
  }

  runApp(
    const ProviderScope(
      child: MotoCareApp(),
    ),
  );
}

final _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const ComponentPreviewScreen(),
    ),
  ],
);

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MotoCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
