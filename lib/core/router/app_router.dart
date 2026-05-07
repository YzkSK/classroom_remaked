// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/assignments/assignments_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
import '../../presentation/views/shared/scaffold_with_nav.dart';
import '../../presentation/views/splash/splash_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';
      final isSignedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      if (!isSignedIn && loc != '/sign-in' && loc != '/splash') {
        return '/sign-in';
      }
      if (isSignedIn && (loc == '/sign-in' || loc == '/splash')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/assignments',
              builder: (_, __) => const AssignmentsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
