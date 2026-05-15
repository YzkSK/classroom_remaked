// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/assignments/assignments_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/course_detail_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
import '../../presentation/views/notification_setup/notification_setup_screen.dart';
import '../../presentation/views/search/search_screen.dart';
import '../../presentation/views/settings/settings_screen.dart';
import '../../presentation/views/shared/scaffold_with_nav.dart';
import '../../presentation/views/splash/splash_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      if (authState.isLoading) return '/splash';

      final isSignedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      if (!isSignedIn && loc != '/sign-in') return '/sign-in';
      if (!isSignedIn) return null;

      // サインイン済み: オンボーディング確認
      if (loc == '/sign-in' || loc == '/splash') {
        final prefsDs = ref.read(userPreferencesDataSourceProvider);
        final onboardingDone = await prefsDs.getOnboardingDone();
        return onboardingDone ? '/dashboard' : '/notification-setup';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: '/notification-setup',
        builder: (_, __) => const NotificationSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'courses/:courseId',
                  builder: (_, state) => CourseDetailScreen(
                    courseId: state.pathParameters['courseId']!,
                    courseName: state.uri.queryParameters['name'] ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/assignments',
              builder: (_, __) => const AssignmentsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
