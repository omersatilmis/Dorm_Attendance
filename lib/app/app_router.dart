import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

import '../features/homepage/presentation/pages/home_page.dart';
import '../features/management/presentation/pages/management_dashboard.dart';
import '../features/management/presentation/pages/teacher_management_page.dart';
import '../features/management/presentation/pages/group_management_page.dart';
import '../features/management/presentation/pages/student_management_page.dart';
import '../features/attendance/presentation/pages/attendance_page.dart';
import '../features/attendance/presentation/providers/performance_screen.dart'
    as performance_screen;
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.currentUser != null || auth.userProfile != null;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Giriş yapmamışsa ve auth sayfasında değilse → login'e yönlendir
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // Giriş yapmışsa ve hâlâ auth sayfasındaysa → home'a yönlendir
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;

      return null; // Yönlendirme yok
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.management,
        builder: (context, state) => const ManagementDashboard(),
        routes: [
          GoRoute(
            path: AppRoutes.teachers,
            builder: (context, state) => const TeacherManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.groups,
            builder: (context, state) => const GroupManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.students,
            builder: (context, state) => const StudentManagementPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendancePage(),
        routes: [
          GoRoute(
            path: AppRoutes.performance,
            builder: (context, state) =>
                const performance_screen.PerformanceScreen(), // Geçiçi import
          ),
        ],
      ),
    ],
  );
}
