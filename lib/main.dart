import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/providers/auth_providers.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/dashboard/ui/dashboard_screen.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/reports/ui/monthly_report_screen.dart';
import 'features/service/ui/service_form_screen.dart';
import 'features/service/ui/service_history_screen.dart';
import 'features/vehicles/ui/vehicle_form_screen.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Inisialisasi NotificationService dilewati/gagal: $e');
  }

  runApp(
    const ProviderScope(
      child: MotoCareApp(),
    ),
  );
}

class MotoCareApp extends ConsumerWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);

    return MaterialApp.router(
      title: 'MotoCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      refreshListenable: _AuthNotifier(ref),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.asData?.value != null;
        final isOnLogin = state.matchedLocation == '/login';

        // Belum masuk → arahkan ke login
        if (!isLoggedIn && !isOnLogin) return '/login';

        // Sudah masuk tapi di halaman login → arahkan ke beranda
        if (isLoggedIn && isOnLogin) return '/';

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: '/vehicles/add',
          builder: (BuildContext context, GoRouterState state) =>
              const VehicleFormScreen(),
        ),
        GoRoute(
          path: '/vehicles/edit/:id',
          builder: (BuildContext context, GoRouterState state) {
            final vehicleId = state.pathParameters['id'];
            return VehicleFormScreen(vehicleId: vehicleId);
          },
        ),
        GoRoute(
          path: '/service/add',
          builder: (BuildContext context, GoRouterState state) {
            final vehicleId = state.uri.queryParameters['vehicleId'];
            final componentType = state.uri.queryParameters['componentType'];
            return ServiceFormScreen(
              vehicleId: vehicleId,
              initialComponentType: componentType,
            );
          },
        ),
        GoRoute(
          path: '/service/history',
          builder: (BuildContext context, GoRouterState state) =>
              const ServiceHistoryScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (BuildContext context, GoRouterState state) =>
              const MonthlyReportScreen(),
        ),
      ],
    );
  }
}

/// Notifier yang memberitahu GoRouter saat status auth berubah
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final WidgetRef _ref;
}
