import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/charts/presentation/charts_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/measurement/presentation/measurements_page.dart';
import '../../features/measurement/presentation/new_measurement_page.dart';
import '../../features/project/presentation/project_detail_page.dart';
import '../../features/project/presentation/projects_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Transição padrão das rotas empurradas: fade com leve deslize vertical.
CustomTransitionPage<void> _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Configuração de rotas (go_router) com shell de navegação por abas.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (c, s) => const DashboardPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (c, s) => const ProjectsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/measurements',
                builder: (c, s) => const MeasurementsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (c, s) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/measurement/new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) =>
            _fadeSlidePage(s, NewMeasurementPage(projectId: s.extra as int?)),
      ),
      GoRoute(
        path: '/project/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => _fadeSlidePage(
          s,
          ProjectDetailPage(projectId: int.parse(s.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/charts',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => _fadeSlidePage(s, const ChartsPage()),
      ),
    ],
  );
});
