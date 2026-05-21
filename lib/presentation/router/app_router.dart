import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/car_catalog/car_catalog_screen.dart';
import '../screens/car_detail/car_detail_screen.dart';
import '../screens/compare/car_compare_screen.dart';
import '../screens/test_drive/test_drive_form_screen.dart';
import '../screens/test_drive_history/test_drive_history_screen.dart';
import '../../domain/entities/car_entity.dart';

/// Route path constants — use these everywhere instead of raw strings.
abstract final class AppRoutes {
  static const catalog = '/catalog';
  static const carDetail = '/catalog/:carId';
  static const compare = '/compare';
  static const testDriveNew = '/test-drive/new';
  static const testDriveHistory = '/test-drive/history';
}

/// Extra data passed to [CarDetailScreen] via [GoRouter.extra].
/// Avoids re-fetching the car we already have on the catalog screen.
final class CarDetailExtra {
  const CarDetailExtra({required this.car});
  final CarEntity car;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.catalog,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.catalog,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CarCatalogScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.carDetail,
      pageBuilder: (context, state) {
        final extra = state.extra as CarDetailExtra?;
        final carId = state.pathParameters['carId'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: CarDetailScreen(carId: carId, car: extra?.car),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.compare,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CarCompareScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.testDriveNew,
      pageBuilder: (context, state) {
        final carId = state.uri.queryParameters['carId'];
        return CustomTransitionPage(
          key: state.pageKey,
          child: TestDriveFormScreen(preselectedCarId: carId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.testDriveHistory,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TestDriveHistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
      ),
    ),
  ],
);