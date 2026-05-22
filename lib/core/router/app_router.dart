// lib/core/router/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../app.dart';
import '../../core/di/providers.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/assignments/assignment_detail_screen.dart';
import '../../presentation/views/assignments/assignments_screen.dart';
import '../../presentation/views/auth/sign_in_screen.dart';
import '../../presentation/views/dashboard/course_detail_screen.dart';
import '../../presentation/views/dashboard/dashboard_screen.dart';
import '../../presentation/views/notification_setup/notification_setup_screen.dart';
import '../../presentation/views/search/search_screen.dart';
import '../../presentation/views/settings/settings_screen.dart';
import '../../presentation/views/shared/file_viewer_screen.dart';
import '../../presentation/views/shared/scaffold_with_nav.dart';
import '../../presentation/views/splash/splash_screen.dart';
part 'app_router.g.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(AppRouterRef ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
    ref.listen(pendingNotificationRouteProvider, (_, __) => notifyListeners());
    ref.onDispose(dispose);
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) async {
      final authState = ref.read(authViewModelProvider);
      final pendingRoute = ref.read(pendingNotificationRouteProvider);

      if (authState.isLoading) return '/splash';

      final isSignedIn = authState.valueOrNull != null;

      // ウィジェットdeep link (cold start): classroomremaked://assignment?id=xxx
      if (state.uri.scheme == 'classroomremaked') {
        if (!isSignedIn) return '/sign-in';
        final id = state.uri.queryParameters['id'];
        if (id != null && id.isNotEmpty) return '/assignments/$id';
        return '/assignments';
      }

      final loc = state.matchedLocation;

      if (!isSignedIn && loc != '/sign-in') return '/sign-in';
      if (!isSignedIn) return null;

      // 通知・ウィジェットタップからの起動（background resume）
      if (pendingRoute != null) {
        ref.read(pendingNotificationRouteProvider.notifier).clear();
        return pendingRoute;
      }

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
      GoRoute(
        path: '/viewer/:fileId',
        builder: (_, state) => FileViewerScreen(
          fileId: state.pathParameters['fileId']!,
          title: state.uri.queryParameters['title'] ?? 'ファイル',
        ),
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
              routes: [
                GoRoute(
                  path: ':assignmentId',
                  builder: (_, state) => AssignmentDetailScreen(
                    assignmentId: state.pathParameters['assignmentId']!,
                  ),
                ),
              ],
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
