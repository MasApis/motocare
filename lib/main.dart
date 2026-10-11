import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          const HomeScreen(),
    ),
  ],
);

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MotoCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoCare'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'MotoCare Scaffolding Siap',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
