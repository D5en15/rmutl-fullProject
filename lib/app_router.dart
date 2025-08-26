import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------- AUTH ----------
import 'ui/auth/login_page.dart';
import 'ui/auth/register_page.dart';
import 'ui/auth/forgot_password_page.dart';

// ---------- COMMON ----------
import 'ui/common/profile_page.dart';
import 'ui/common/notification_page.dart';
import 'ui/common/settings_page.dart';
import 'ui/common/role_shell.dart';

// ---------- STUDENT ----------
import 'ui/student/home_page.dart' as s;
import 'ui/student/grades_page.dart';
import 'ui/student/edit_grade_page.dart';
import 'ui/student/career_page.dart';

// ---------- TEACHER ----------
import 'ui/teacher/teacher_home_page.dart' as t;
import 'ui/teacher/student_list_page.dart';
import 'ui/teacher/student_detail_page.dart';
import 'ui/teacher/feedback_page.dart';

// ---------- ADMIN ----------
import 'ui/admin/admin_home_page.dart' as a;
import 'ui/admin/user_manage_page.dart';
import 'ui/admin/role_permission_page.dart';
import 'ui/admin/career_config_page.dart';
import 'ui/admin/moderation_page.dart';

// ---------- FORUM (แชร์) ----------
import 'ui/forum/forum_list_page.dart';
import 'ui/forum/post_detail_page.dart';
import 'ui/forum/create_post_page.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _studentShellKey = GlobalKey<NavigatorState>(
    debugLabel: 'studentShell',
  );
  static final _teacherShellKey = GlobalKey<NavigatorState>(
    debugLabel: 'teacherShell',
  );
  static final _adminShellKey = GlobalKey<NavigatorState>(
    debugLabel: 'adminShell',
  );

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('404')),
          body: Center(child: Text('404 • Page not found: ${state.uri}')),
        ),
    routes: [
      // ---------- AUTH ----------
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordPage()),

      // ---------- COMMON (เข้าจากที่ใดก็ได้) ----------
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationPage(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),

      // ================= STUDENT (BottomNav: Home • Career • Board • Setting) =================
      ShellRoute(
        navigatorKey: _studentShellKey,
        builder:
            (context, state, child) => RoleShell(role: 'student', child: child),
        routes: [
          GoRoute(
            path: '/student',
            builder: (_, __) => const s.StudentHomePage(),
            routes: [
              GoRoute(path: 'grades', builder: (_, __) => const GradesPage()),
              GoRoute(
                path: 'grades/edit',
                builder: (_, __) => const EditGradePage(),
              ),
              GoRoute(path: 'career', builder: (_, __) => const CareerPage()),
            ],
          ),
          GoRoute(
            path: '/student/career',
            builder: (_, __) => const CareerPage(),
          ),
          GoRoute(
            path: '/student/forum',
            builder: (_, __) => const ForumListPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreatePostPage(),
              ),
              GoRoute(
                path: ':postId',
                builder:
                    (_, s) =>
                        PostDetailPage(postId: s.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/student/settings',
            builder: (_, __) => const SettingsPage(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/student/notifications',
            builder: (_, __) => const NotificationPage(),
          ),
        ],
      ),

      // ================= TEACHER (BottomNav: Home • Board • Setting) =================
      ShellRoute(
        navigatorKey: _teacherShellKey,
        builder:
            (context, state, child) => RoleShell(role: 'teacher', child: child),
        routes: [
          GoRoute(
            path: '/teacher',
            builder: (_, __) => const t.TeacherHomePage(),
            routes: [
              GoRoute(
                path: 'students',
                builder: (_, __) => const StudentListPage(),
              ),
              GoRoute(
                path: 'students/:id',
                builder:
                    (_, s) =>
                        StudentDetailPage(studentId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: 'feedback',
                builder: (_, __) => const FeedbackPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/teacher/forum',
            builder: (_, __) => const ForumListPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreatePostPage(),
              ),
              GoRoute(
                path: ':postId',
                builder:
                    (_, s) =>
                        PostDetailPage(postId: s.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/teacher/settings',
            builder: (_, __) => const SettingsPage(),
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/teacher/notifications',
            builder: (_, __) => const NotificationPage(),
          ),
        ],
      ),

      // ================= ADMIN (BottomNav: Home • Users • CareerCfg • Moderation) =================
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder:
            (context, state, child) => RoleShell(role: 'admin', child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const a.AdminHomePage(),
            routes: [
              GoRoute(
                path: 'users',
                builder: (_, __) => const UserManagePage(),
              ),
              GoRoute(
                path: 'roles',
                builder: (_, __) => const RolePermissionPage(),
              ),
              GoRoute(
                path: 'career-config',
                builder: (_, __) => const CareerConfigPage(),
              ),
              GoRoute(
                path: 'moderation',
                builder: (_, __) => const ModerationPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UserManagePage(),
          ),
          GoRoute(
            path: '/admin/career-config',
            builder: (_, __) => const CareerConfigPage(),
          ),
          GoRoute(
            path: '/admin/moderation',
            builder: (_, __) => const ModerationPage(),
          ),
          GoRoute(
            path: '/admin/forum',
            builder: (_, __) => const ForumListPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreatePostPage(),
              ),
              GoRoute(
                path: ':postId',
                builder:
                    (_, s) =>
                        PostDetailPage(postId: s.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const SettingsPage(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (_, __) => const NotificationPage(),
          ),
        ],
      ),

      // ---------- Global forum (optional) ----------
      GoRoute(
        path: '/forum',
        builder: (_, __) => const ForumListPage(),
        routes: [
          GoRoute(path: 'create', builder: (_, __) => const CreatePostPage()),
          GoRoute(
            path: ':postId',
            builder:
                (_, s) => PostDetailPage(postId: s.pathParameters['postId']!),
          ),
        ],
      ),
    ],
  );
}
