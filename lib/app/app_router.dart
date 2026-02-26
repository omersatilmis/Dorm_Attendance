import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/management/presentation/pages/management_dashboard.dart';
import '../features/management/presentation/pages/management_sub_pages.dart';
import '../features/attendance/presentation/pages/attendance_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/management',
        builder: (context, state) => const ManagementDashboard(),
        routes: [
          GoRoute(
            path: 'teachers',
            builder: (context, state) => const TeacherManagementPage(),
          ),
          GoRoute(
            path: 'groups',
            builder: (context, state) => const GroupManagementPage(),
          ),
          GoRoute(
            path: 'students',
            builder: (context, state) => const StudentManagementPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendancePage(),
      ),
    ],
  );
}
